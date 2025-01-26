#!/bin/bash
# start-aider.sh

# Set the API base URL to your RunPod proxy endpoint
export OPENAI_API_BASE=https://XXXXXXXXXXXXX-8080.proxy.runpod.net/v1

# Set the API type to openai
export OPENAI_API_TYPE=openai

# Since we're using the proxy, we can use a dummy key
export OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Run aider with a generic model name that the API expects
aider --model gpt-4 --dark-mode --pretty 