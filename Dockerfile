# Use CUDA 12.1.0 base image for GPU support
# - Required for A40 GPUs on RunPod
# - Compatible with llama.cpp CUDA acceleration
# - Need devel variant for build tools
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# Add GitHub Container Registry metadata for better discoverability
LABEL org.opencontainers.image.source=https://github.com/rybruscoe/deepseek-server
LABEL org.opencontainers.image.description="DeepSeek LLM Server with CUDA acceleration for RunPod"
LABEL org.opencontainers.image.licenses=MIT

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and dependencies
# - build-essential: Required for compiling llama.cpp
# - cmake: Used for llama.cpp build system
# - meson and ninja-build: Used for building llama.cpp using meson
# - pkg-config: Used for building llama.cpp
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    wget \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
# It's safe to run pip as root in a container context
RUN pip3 install --no-cache-dir -r requirements.txt

# Set up CUDA environment and stubs
WORKDIR /app
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV PATH=$PATH:$CUDA_HOME/bin

# Link CUDA stubs
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/cuda-stubs.conf && \
    ldconfig

# Build llama.cpp with CUDA support
RUN git clone https://github.com/ggerganov/llama.cpp.git && \
    cd llama.cpp && \
    mkdir build && \
    cd build && \
    cmake .. -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="75;86" && \
    VERBOSE=1 cmake --build . --config Release -j$(nproc)

# Create directory for model storage
# This will be mounted as a volume in RunPod
RUN mkdir -p /app/models

# Copy application code and scripts
COPY api_server.py /app/
COPY start.sh /app/
COPY download_model.sh /app/

# Set working directory for runtime
WORKDIR /app

# Make scripts executable
RUN chmod +x start.sh download_model.sh

# Expose ports for API access
# These ports will be exposed via RunPod's proxy
EXPOSE 8080 8000

# Environment variables
ENV MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"

# Add these environment variables for better CUDA performance
ENV CUDA_VISIBLE_DEVICES=all
ENV CUDA_DEVICE_ORDER=PCI_BUS_ID

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start services via start.sh
CMD ["./start.sh"] 