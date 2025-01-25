# Use CUDA base image for GPU support
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# Install essential build tools and dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    wget \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Clone and build llama.cpp with optimizations
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git && \
    cd llama.cpp && \
    # Build with CUDA, BLAS, and other optimizations
    LLAMA_CUBLAS=1 CMAKE_CUDA_ARCHITECTURES=86 make -j && \
    # Build server binary
    make server && \
    # Build quantization tools
    make quantize

# Create directory for models
RUN mkdir -p /app/models

# Copy the FastAPI server code
COPY api_server.py /app/
COPY start.sh /app/

# Set working directory
WORKDIR /app

# Make start script executable
RUN chmod +x start.sh

# Expose ports (though with Tailscale, direct port exposure isn't necessary)
EXPOSE 8080 8000

# Environment variable for Tailscale auth key
ENV TS_AUTHKEY=""

# Start Tailscale and servers
CMD ["./start.sh"] 