#!/bin/bash

# URLs for the DeepSeek R1 Distill Qwen F16 model parts
MODEL_BASE_URL="https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-32B-F16"
MODEL_PATH="/app/models/DeepSeek-R1-Distill-Qwen-32B-F16.gguf"

# Download and combine model parts if the final model doesn't exist
if [ ! -f "$MODEL_PATH" ]; then
    echo "Downloading model parts..."
    mkdir -p $(dirname "$MODEL_PATH")
    
    # Download part 1
    echo "Downloading part 1 of 2..."
    wget -O "${MODEL_PATH}.part1" "${MODEL_BASE_URL}/DeepSeek-R1-Distill-Qwen-32B-F16-00001-of-00002.gguf"
    
    # Download part 2
    echo "Downloading part 2 of 2..."
    wget -O "${MODEL_PATH}.part2" "${MODEL_BASE_URL}/DeepSeek-R1-Distill-Qwen-32B-F16-00002-of-00002.gguf"
    
    # Combine parts
    echo "Combining model parts..."
    cat "${MODEL_PATH}.part1" "${MODEL_PATH}.part2" > "$MODEL_PATH"
    
    # Clean up parts
    rm "${MODEL_PATH}.part1" "${MODEL_PATH}.part2"
    
    # Verify combined file exists
    if [ ! -f "$MODEL_PATH" ]; then
        echo "Error: Model combination failed"
        exit 1
    fi
    
    echo "Model download and combination complete"
else
    echo "Model already exists, skipping download"
fi 