# Use CUDA base image for GPU support
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# Add GitHub Container Registry metadata for better discoverability
LABEL org.opencontainers.image.source=https://github.com/rybruscoe/deepseek-server
LABEL org.opencontainers.image.description="DeepSeek LLM Server with Tailscale integration"
LABEL org.opencontainers.image.licenses=MIT

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and dependencies
# - build-essential: Required for compiling llama.cpp
# - cmake: Used for llama.cpp build system
# - iptables, iproute2, kmod: Required for Tailscale networking
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    wget \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    iptables \
    iproute2 \
    kmod \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale for secure networking
# Using the official Tailscale package repository
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories and TUN device for Tailscale
# TUN device is required for VPN functionality
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale && \
    mkdir -p /dev/net && \
    mknod /dev/net/tun c 10 200 && \
    chmod 600 /dev/net/tun

# Install Python dependencies
COPY requirements.txt .
# It's safe to run pip as root in a container context
RUN pip3 install --no-cache-dir -r requirements.txt

# Clone and build llama.cpp with optimizations
WORKDIR /app
# Set CUDA environment variables for GPU support
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV PATH=$PATH:$CUDA_HOME/bin

# Link CUDA libraries for proper runtime resolution
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/cuda-stubs.conf && \
    ldconfig

# Build llama.cpp with CUDA support
# - GGML_CUDA=ON: Enable CUDA acceleration
# - CMAKE_CUDA_ARCHITECTURES=86: Optimized for A40 GPUs
RUN git clone --depth 1 https://github.com/ggerganov/llama.cpp.git && \
    cd llama.cpp && \
    mkdir build && \
    cd build && \
    cmake .. -DGGML_CUDA=ON \
            -DCMAKE_CUDA_ARCHITECTURES=86 \
            -DCMAKE_CUDA_FLAGS="-I${CUDA_HOME}/include" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs && \
    cmake --build . --config Release -j && \
    mkdir -p /app/llama.cpp/bin && \
    cp bin/* /app/llama.cpp/bin/

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
# Note: When using Tailscale, direct port exposure isn't necessary
EXPOSE 8080 8000

# Environment variables
# TS_AUTHKEY will be provided at runtime via RunPod
ENV TS_AUTHKEY=""
ENV MODEL_PATH="/app/models/deepseek-coder-33b-base.Q8_0.gguf"

# Start services via start.sh
CMD ["./start.sh"] 