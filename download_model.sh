#!/bin/bash

# URL for the DeepSeek R1 Distill Qwen model
# Using Q8_0 quantization for best quality/performance balance
MODEL_URL="https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"
MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"

# Download model only if it doesn't exist
# This prevents re-downloading when container restarts
# The model file is stored in a persistent volume mounted at /app/models
if [ ! -f "$MODEL_PATH" ]; then
    echo "Downloading model..."
    wget -O "$MODEL_PATH" "$MODEL_URL"
else
    echo "Model already exists, skipping download"
fi 