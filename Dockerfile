# Use CUDA base image for GPU support
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

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
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Clone and build llama.cpp with optimizations
WORKDIR /app
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV PATH=$PATH:$CUDA_HOME/bin

# Link CUDA libraries
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/cuda-stubs.conf && \
    ldconfig

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

# Create directory for models
RUN mkdir -p /app/models

# Copy the FastAPI server code and scripts
COPY api_server.py /app/
COPY start.sh /app/
COPY download_model.sh /app/

# Set working directory
WORKDIR /app

# Make scripts executable
RUN chmod +x start.sh download_model.sh

# Expose ports (though with Tailscale, direct port exposure isn't necessary)
EXPOSE 8080 8000

# Environment variables
ENV TS_AUTHKEY=""
ENV MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"

# Start Tailscale and servers
CMD ["./start.sh"] 