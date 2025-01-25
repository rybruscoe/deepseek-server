# DeepSeek LLM Server

A GPU-accelerated server for running the DeepSeek-R1-Distill-Qwen-32B model with llama.cpp, FastAPI, and Tailscale integration.

## Requirements

- NVIDIA GPU with CUDA support (tested on A40)
- Docker with NVIDIA Container Toolkit
- Tailscale account

## Quick Start

1. Get a Tailscale auth key from https://login.tailscale.com/admin/settings/keys

2. Build the container:
```bash
docker build -t deepseek-server .
```

3. Run the container:
```bash
docker run --gpus all \
  -v /path/to/model:/app/models \
  -e TS_AUTHKEY="tskey-auth-xxxxx" \
  deepseek-server
```

4. Access the API through Tailscale network:
```python
import requests

response = requests.post(
    "http://llm-gpu-pod:8000/v1/completions",
    json={
        "prompt": "What is 1+1?",
        "temperature": 0.7,
        "max_tokens": 512
    }
)
print(response.json()["text"])
```

## API Endpoints

- `POST /v1/completions`: Generate text completions
- `GET /health`: Check server status

## Environment Variables

- `TS_AUTHKEY`: Tailscale authentication key (required)

## Model

This server is configured for the DeepSeek-R1-Distill-Qwen-32B-F16 model. Download it from:
https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF

## License

MIT License 