#!/bin/bash

MODEL_URL="https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"
MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"

if [ ! -f "$MODEL_PATH" ]; then
    echo "Downloading model..."
    wget -O "$MODEL_PATH" "$MODEL_URL"
else
    echo "Model already exists, skipping download"
fi 