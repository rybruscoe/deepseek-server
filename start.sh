#!/bin/bash

# Exit on error
set -e

# Function for logging
log() {
    echo "[$(date -u)] $1"
}

# Setup TUN device
setup_tun() {
    if [ ! -e /dev/net/tun ]; then
        log "Creating TUN device..."
        mkdir -p /dev/net
        mknod /dev/net/tun c 10 200
        chmod 600 /dev/net/tun
    fi
}

# Start Tailscale
start_tailscale() {
    setup_tun
    log "Starting Tailscale daemon..."
    tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
    
    # Wait for daemon to start
    sleep 2
    
    if [ -z "$TS_AUTHKEY" ]; then
        log "ERROR: No Tailscale auth key provided"
        exit 1
    fi
    
    log "Authenticating with Tailscale..."
    tailscale up --authkey="$TS_AUTHKEY" --hostname="llm-gpu-pod"
    
    # Verify Tailscale connection
    if ! tailscale status; then
        log "ERROR: Tailscale failed to connect"
        exit 1
    fi
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