#!/bin/bash

# Wait for Ollama to start
sleep 5

# Pull the DeepSeek model
ollama pull hf.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF:F16

# Keep the container running
tail -f /dev/null 