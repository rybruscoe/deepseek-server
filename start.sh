#!/bin/bash

# Exit on error
set -e

# Function for logging
log() {
    echo "[$(date -u)] $1"
}

# Start Tailscale
start_tailscale() {
    log "Starting Tailscale daemon..."
    tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
    
    # Wait for daemon to start
    sleep 2
    
    if [ -z "$TS_AUTHKEY" ]; then
        log "ERROR: No Tailscale auth key provided"
        exit 1
    }
    
    log "Authenticating with Tailscale..."
    tailscale up --authkey="$TS_AUTHKEY" --hostname="llm-gpu-pod"
    
    # Verify Tailscale connection
    if ! tailscale status; then
        log "ERROR: Tailscale failed to connect"
        exit 1
    }
    log "Tailscale connected successfully"
}

# Download model if needed
log "Checking model..."
./download_model.sh

# Start Tailscale
start_tailscale

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