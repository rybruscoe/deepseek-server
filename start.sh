#!/bin/bash

# Exit on error
set -e

# Function for logging
log() {
    echo "[$(date -u)] $1"
}

# Download model if needed
log "Checking model..."
./download_model.sh

# Start llama.cpp server
log "Starting llama.cpp server..."
./llama.cpp/bin/server \
    --model "$MODEL_PATH" \
    --n-gpu-layers 80 \
    --threads 8 \
    --ctx-size 8192 \
    --batch-size 1024 \
    --temp 0.7 \
    --repeat-penalty 1.1 \
    --gpu-memory-utilization 0.9 \
    --host 0.0.0.0 \
    --port 8080 &

# Start FastAPI server
log "Starting FastAPI server..."
uvicorn api_server:app --host 0.0.0.0 --port 8000 --workers 4 