#!/bin/bash

# Exit on error
set -e

# Download model if needed
./download_model.sh

# Start Tailscale if auth key is provided
if [ ! -z "$TS_AUTHKEY" ]; then
    echo "Starting Tailscale..."
    tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
    sleep 2
    tailscale up --authkey="$TS_AUTHKEY" --hostname="llm-gpu-pod"
else
    echo "No Tailscale auth key provided. Skipping Tailscale setup."
fi

# Start llama.cpp server in background
echo "Starting llama.cpp server..."
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
echo "Starting FastAPI server..."
uvicorn api_server:app --host 0.0.0.0 --port 8000 --workers 4 