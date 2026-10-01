import os
import json
import logging
import httpx
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

app = FastAPI(
    title="SafeRoute AI API",
    description="Backend AI explanation proxy service for SafeRoute AI walking route safety assistant.",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Read Secrets strictly from Environment Variables (No hardcoded secrets)
def get_gemini_keys() -> List[str]:
    keys = []
    k1 = os.environ.get("GEMINI_API_KEY")
    if k1 and not k1.startswith("YOUR_"):
        keys.append(k1)
    return keys

def get_groq_keys() -> List[str]:
    keys = []
    for var_name in ["GROQ_API_KEY_1", "GROQ_API_KEY_2", "GROQ_API_KEY"]:
        k = os.environ.get(var_name)
        if k and not k.startswith("YOUR_"):
            keys.append(k)
    return keys

SYSTEM_PROMPT = """You are SafeRoute AI's explanation assistant.
Your sole job is to translate structured, verified pedestrian routing & community hazard data into clear, factual, natural language insights.

CRITICAL RULES:
1. ONLY use the verified data facts explicitly supplied in the request payload.
2. NEVER invent unverified hazards, crime statistics, police presence, street lighting, traffic conditions, or safety incidents.
3. NEVER create, modify, or override numerical safety scores.
4. NEVER claim any route is "100% safe" or "guaranteed safe".
5. Keep explanations neutral, helpful, and concise.
6. Return your response ONLY as a valid JSON object with these exact keys:
   - "summary": string (1-2 sentences high level overview)
   - "key_points": list of strings (2-3 concise bullet points)
   - "tradeoffs": list of strings (1-2 distance vs safety trade-off statements)
   - "confidence_note": string (statement on data freshness/coverage)
   - "disclaimer": string (standard statement: "AI insight based on available community reports. Reports may be incomplete.")
"""

# Pydantic Input Validation Models
class RouteExplainRequest(BaseModel):
    safety_score: int = Field(default=100, ge=0, le=100)
    distance_km: Any = "0.0"
    duration_min: int = Field(default=0, ge=0)
    signals: List[Any] = Field(default_factory=list)

class RouteComparisonRequest(BaseModel):
    candidates: List[Dict[str, Any]] = Field(default_factory=list)

class HazardExplainRequest(BaseModel):
    hazard_type: str = "hazard"
    distance_m: float = 0.0
    description: Optional[str] = ""
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)

class QuestionRequest(BaseModel):
    question: str
    navigation_state: Optional[Dict[str, Any]] = Field(default_factory=dict)

class TripInsightRequest(BaseModel):
    trip_summary: Dict[str, Any] = Field(default_factory=dict)

async def call_gemini_api(key: str, system_prompt: str, user_content: str) -> Dict[str, Any]:
    """Call Google Gemini API with fallback models."""
    models_to_try = ["gemini-1.5-flash", "gemini-2.0-flash", "gemini-pro"]
    last_error = None
    
    full_prompt = f"{system_prompt}\n\nUser Data Request:\n{user_content}\n\nRespond ONLY with valid JSON."
    payload = {
        "contents": [{"parts": [{"text": full_prompt}]}],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 600,
            "responseMimeType": "application/json"
        }
    }
    
    async with httpx.AsyncClient(timeout=6.0) as client:
        for model in models_to_try:
            try:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
                headers = {
                    'Content-Type': 'application/json',
                    'x-goog-api-key': key
                }
                res = await client.post(url, json=payload, headers=headers)
                if res.status_code == 200:
                    res_data = res.json()
                    text = res_data['candidates'][0]['content']['parts'][0]['text']
                    return json.loads(text)
                else:
                    last_error = f"HTTP {res.status_code}: {res.text}"
            except Exception as e:
                last_error = e

    raise Exception(f"Gemini API call failed: {last_error}")

async def call_groq_api(key: str, system_prompt: str, user_content: str) -> Dict[str, Any]:
    """Call Groq OpenAI-Compatible Chat Completion API."""
    url = "https://api.groq.com/openai/v1/chat/completions"
    
    payload = {
        "model": "llama-3.3-70b-versatile",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"{user_content}\n\nRespond ONLY with valid JSON adhering to the specified schema."}
        ],
        "temperature": 0.2,
        "max_tokens": 600,
        "response_format": {"type": "json_object"}
    }
    
    async with httpx.AsyncClient(timeout=6.0) as client:
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {key}'
        }
        res = await client.post(url, json=payload, headers=headers)
        if res.status_code == 200:
            res_data = res.json()
            text = res_data['choices'][0]['message']['content']
            return json.loads(text)
        else:
            raise Exception(f"Groq API error {res.status_code}: {res.text}")

async def execute_ai_with_failover(system_prompt: str, user_content: str) -> tuple[Dict[str, Any], str]:
    """Execute AI request with multi-key and multi-provider automatic failover rotation."""
    providers = []
    
    # Add Gemini keys
    for k in get_gemini_keys():
        providers.append(("Gemini", k, call_gemini_api))
            
    # Add Groq keys
    for i, k in enumerate(get_groq_keys()):
        providers.append((f"Groq-Key-{i+1}", k, call_groq_api))
            
    if not providers:
        raise Exception("No AI API keys configured. Set GEMINI_API_KEY or GROQ_API_KEY in environment variables.")

    errors = []
    for provider_name, key, func in providers:
        try:
            logging.info(f"Attempting AI request with provider: {provider_name}")
            result = await func(key, system_prompt, user_content)
            logging.info(f"Successfully generated response via {provider_name}")
            return result, provider_name
        except Exception as e:
            logging.warning(f"Provider {provider_name} failed: {e}. Trying next available provider...")
            errors.append(f"{provider_name}: {str(e)}")
            
    raise Exception(f"All configured AI API keys failed. Errors: {'; '.join(errors)}")

# Health Check Endpoints
@app.get("/health")
@app.get("/api/health")
async def health_check():
    return {
        "status": "ok",
        "service": "SafeRoute AI API",
        "gemini_configured": len(get_gemini_keys()) > 0,
        "groq_configured": len(get_groq_keys()) > 0
    }

# Explanation Endpoints
@app.post("/api/explain-route")
async def explain_route(data: RouteExplainRequest):
    user_content = f"""Route Safety Score: {data.safety_score}/100
Route Distance: {data.distance_km} km
Route Duration: {data.duration_min} minutes
Verified Signals: {json.dumps(data.signals)}"""
    return await _process_ai_request(user_content)

@app.post("/api/explain-comparison")
async def explain_comparison(data: RouteComparisonRequest):
    user_content = f"Route Candidates Comparison:\n{json.dumps(data.candidates, indent=2)}"
    return await _process_ai_request(user_content)

@app.post("/api/explain-hazard")
async def explain_hazard(data: HazardExplainRequest):
    sanitized_desc = data.description.replace("<", "&lt;").replace(">", "&gt;") if data.description else ""
    user_content = f"""Single Hazard Inspection:
Hazard Type: {data.hazard_type}
Distance from route: {data.distance_m} meters
Reported Description: <untrusted_content>{sanitized_desc}</untrusted_content>
Confidence Level: {data.confidence}"""
    return await _process_ai_request(user_content)

@app.post("/api/answer-question")
async def answer_question(data: QuestionRequest):
    sanitized_q = data.question.replace("<", "&lt;").replace(">", "&gt;")
    user_content = f"""User Question: <untrusted_content>{sanitized_q}</untrusted_content>
Current Navigation State & Context:
{json.dumps(data.navigation_state, indent=2)}"""
    return await _process_ai_request(user_content)

@app.post("/api/trip-insight")
async def trip_insight(data: TripInsightRequest):
    user_content = f"Completed Trip Metrics:\n{json.dumps(data.trip_summary, indent=2)}"
    return await _process_ai_request(user_content)

async def _process_ai_request(user_content: str):
    try:
        response_json, provider_used = await execute_ai_with_failover(SYSTEM_PROMPT, user_content)
        response_json['provider_used'] = provider_used
        return response_json
    except Exception as e:
        logging.error(f"Error processing AI request: {e}")
        raise HTTPException(
            status_code=500,
            detail={
                "error": True,
                "message": str(e),
                "fallback_available": True
            }
        )

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
