# syntax=docker/dockerfile:1

# Use CUDA 12.2.0 base image for GPU support
FROM --platform=linux/amd64 nvidia/cuda:12.2.0-devel-ubuntu22.04 AS builder

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
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Create app directory
RUN mkdir -p /app/llama.cpp/build/bin

# Build llama.cpp with CUDA support
WORKDIR /tmp
RUN git clone https://github.com/ggerganov/llama.cpp.git && \
    cd llama.cpp && \
    git checkout master && \
    mkdir build && \
    cd build && \
    CFLAGS="-march=x86-64" CXXFLAGS="-march=x86-64" cmake .. -DGGML_CUDA=ON \
        -DCMAKE_CUDA_ARCHITECTURES="75;86" \
        -DCMAKE_CUDA_FLAGS="-I${CUDA_HOME}/include" \
        -DCMAKE_EXE_LINKER_FLAGS="-L${CUDA_HOME}/lib64 -lcuda -lcudart" && \
    cmake --build . --config Release -j$(nproc) && \
    cp bin/llama-server /app/llama.cpp/build/bin/ && \
    chmod +x /app/llama.cpp/build/bin/llama-server

# Create final image
FROM --platform=linux/amd64 nvidia/cuda:12.2.0-runtime-ubuntu22.04

# Install required runtime packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages
COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn

# Copy llama.cpp server
COPY --from=builder /app/llama.cpp/build/bin/llama-server /app/llama.cpp/build/bin/

# Create directory for model storage
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
EXPOSE 8080 8000

# Environment variables
ENV MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start services via start.sh
CMD ["./start.sh"] 