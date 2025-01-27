# Use CUDA 12.2.0 base image for GPU support
# - Required for A40 GPUs on RunPod
# - Compatible with llama.cpp CUDA acceleration
# - Need devel variant for build tools
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Add GitHub Container Registry metadata for better discoverability
LABEL org.opencontainers.image.source=https://github.com/rybruscoe/deepseek-server
LABEL org.opencontainers.image.description="DeepSeek R1 Distill Qwen 32B LLM Server with CUDA acceleration for RunPod"
LABEL org.opencontainers.image.licenses=MIT

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set up CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV CUDA_VISIBLE_DEVICES=all
ENV CUDA_DEVICE_ORDER=PCI_BUS_ID

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

# Build llama.cpp with CUDA support
RUN git clone https://github.com/ggerganov/llama.cpp.git && \
    cd llama.cpp && \
    mkdir build && \
    cd build && \
    cmake .. -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="75;86" && \
    VERBOSE=1 cmake --build . --config Release -j$(nproc) && \
    ls -l bin/llama-server && \
    chmod +x bin/llama-server

# Add after llama.cpp build
RUN if [ ! -f "/app/llama.cpp/build/bin/llama-server" ]; then \
    echo "Error: llama.cpp server binary not found" && exit 1; \
fi

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
# NOTE: Use Q4_K_M quantization for local testing with RTX 3090 or less than two A6000 GPUs
# For production on RunPod with A40/A100, use F16 version for better performance:
# ENV MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"
ENV MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start services via start.sh
CMD ["./start.sh"] 