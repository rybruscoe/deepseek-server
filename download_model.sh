#!/bin/bash

# URL for the DeepSeek R1 Distill Qwen model
# NOTE: Using Q4_K_M quantization temporarily for local testing with RTX 3090
# For production on RunPod, switch to F16 version:
# MODEL_URL="https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"
MODEL_URL="https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"
MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"

# Download model only if it doesn't exist
# This prevents re-downloading when container restarts
# The model file is stored in a persistent volume mounted at /app/models
if [ ! -f "$MODEL_PATH" ]; then
    echo "Downloading model..."
    mkdir -p $(dirname "$MODEL_PATH")
    wget -O "$MODEL_PATH" "$MODEL_URL"
else
    echo "Model already exists, skipping download"
fi 