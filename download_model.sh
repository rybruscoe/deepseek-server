#!/bin/bash

# URL for the DeepSeek Coder model
# Using Q8_0 quantization for best quality (equivalent to F16 precision)
MODEL_URL="https://huggingface.co/TheBloke/DeepSeek-Coder-33B-Base-GGUF/resolve/main/deepseek-coder-33b-base.Q8_0.gguf"
MODEL_PATH="/app/models/deepseek-coder-33b-base.Q8_0.gguf"

# Download model only if it doesn't exist
# This prevents re-downloading when container restarts
# The model file is stored in a persistent volume mounted at /app/models
if [ ! -f "$MODEL_PATH" ]; then
    echo "Downloading model..."
    wget -O "$MODEL_PATH" "$MODEL_URL"
else
    echo "Model already exists, skipping download"
fi 