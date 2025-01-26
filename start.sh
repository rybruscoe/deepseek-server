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

# Start llama.cpp server with correct path
log "Starting llama.cpp server..."
./llama.cpp/build/bin/server \
    --model "$MODEL_PATH" \
    --n-gpu-layers 70 \
    --threads 8 \
    --ctx-size 8192 \
    --batch-size 1024 \
    --temp 0.7 \
    --repeat-penalty 1.1 \
    --gpu-memory-utilization 0.9 \
    --host 0.0.0.0 \
    --port 8080 \
    --mlock \
    --numa &

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