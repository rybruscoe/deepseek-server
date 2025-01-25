#!/bin/bash

MODEL_URL="https://huggingface.co/TheBloke/DeepSeek-Coder-33B-Base-GGUF/resolve/main/deepseek-coder-33b-base.Q8_0.gguf"
MODEL_PATH="/app/models/deepseek-coder-33b-base.Q8_0.gguf"

if [ ! -f "$MODEL_PATH" ]; then
    echo "Downloading model..."
    wget -O "$MODEL_PATH" "$MODEL_URL"
else
    echo "Model already exists, skipping download"
fi 