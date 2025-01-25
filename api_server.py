from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import asyncio
from typing import Optional
import logging

app = FastAPI(title="LLM API Server")
logging.basicConfig(level=logging.INFO)

class CompletionRequest(BaseModel):
    prompt: str
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 512
    stop: Optional[list[str]] = None

class CompletionResponse(BaseModel):
    text: str
    usage: dict

@app.post("/v1/completions")
async def create_completion(request: CompletionRequest):
    try:
        # Format prompt for DeepSeek
        formatted_prompt = f" {request.prompt} "
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "http://localhost:8080/completion",
                json={
                    "prompt": formatted_prompt,
                    "temperature": request.temperature,
                    "n_predict": request.max_tokens,
                    "stop": request.stop or []
                },
                timeout=30.0
            )
            
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail="LLM server error")
            
            result = response.json()
            
            return CompletionResponse(
                text=result["content"],
                usage={
                    "prompt_tokens": result.get("prompt_tokens", 0),
                    "completion_tokens": result.get("completion_tokens", 0),
                    "total_tokens": result.get("total_tokens", 0)
                }
            )
            
    except Exception as e:
        logging.error(f"Error processing request: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "healthy"} 