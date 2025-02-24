#!/bin/bash

# Exit on error
set -e

# Function for logging
log() {
    echo "[$(date -u)] $1"
}

# Function to cleanup background processes
cleanup() {
    log "Shutting down servers..."
    pkill -P $$
    exit 0
}

# Set up trap for cleanup
trap cleanup SIGTERM SIGINT

# Download model if needed
log "Checking model..."
./download_model.sh

# Check for CUDA GPU
if nvidia-smi &> /dev/null; then
    log "CUDA GPU detected, using GPU acceleration"
    # Optimized settings for A40 (48GB) with F16 model
    GPU_ARGS="--n-gpu-layers 80 --gpu-memory-utilization 0.9"
else
    log "No CUDA GPU detected, falling back to CPU only mode"
    GPU_ARGS=""
fi

# Start llama.cpp server with correct path
log "Starting llama.cpp server..."
/app/llama.cpp/build/bin/llama-server \
    --model "$MODEL_PATH" \
    --threads 16 \
    --ctx-size 32768 \
    --batch-size 2048 \
    --temp 0.7 \
    --repeat-penalty 1.1 \
    --host 0.0.0.0 \
    --port 8080 \
    --mlock \
    $GPU_ARGS &

# Wait for llama.cpp server to start
sleep 5

# Check if server started successfully
if ! curl -s http://localhost:8080/health > /dev/null; then
    log "Error: llama.cpp server failed to start"
    exit 1
fi

# Start FastAPI server
log "Starting FastAPI server..."
uvicorn api_server:app --host 0.0.0.0 --port 8000 --workers 4 