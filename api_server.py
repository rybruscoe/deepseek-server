"""
FastAPI server for DeepSeek Coder LLM using llama.cpp backend.

This server provides a simple API interface to interact with the DeepSeek Coder model.
It uses FastAPI for the web framework and communicates with the llama.cpp server
running locally on port 8080.

Environment Variables:
    MODEL_PATH: Path to the GGUF model file (set in Dockerfile)

Endpoints:
    POST /v1/completions: Generate text completions
    GET /health: Check server status

Usage:
    The server runs on port 8000 and is accessible through Tailscale network
    or directly via HTTP if ports are exposed.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import os

app = FastAPI(title="DeepSeek Coder API")

class CompletionRequest(BaseModel):
    """
    Request model for text completion endpoint.
    
    Attributes:
        prompt (str): The input text to generate completion for
        temperature (float): Controls randomness in generation (0.0 to 1.0)
        max_tokens (int): Maximum number of tokens to generate
    """
    prompt: str
    temperature: float = 0.7
    max_tokens: int = 512

LLAMA_SERVER = "http://localhost:8080"

@app.get("/health")
async def health():
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{LLAMA_SERVER}/health")
            if response.status_code == 200:
                return {"status": "healthy", "model": os.getenv("MODEL_PATH")}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))
    raise HTTPException(status_code=503, detail="Llama server unhealthy")

@app.post("/v1/completions")
async def create_completion(request: CompletionRequest):
    """
    Generate text completion for the given prompt.
    
    Args:
        request (CompletionRequest): The completion request parameters
        
    Returns:
        dict: Generated text and metadata
        
    Raises:
        HTTPException: If llama.cpp server is unreachable
    """
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{LLAMA_SERVER}/completion",
                json={
                    "prompt": request.prompt,
                    "temperature": request.temperature,
                    "n_predict": request.max_tokens
                }
            )
            return response.json()
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=str(e)) 