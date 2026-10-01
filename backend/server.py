import os
import json
import logging
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

PORT = int(os.environ.get('PORT', 8000))

# Secure API Key Pool with Failover Order: Gemini Key -> Groq Key 1 -> Groq Key 2
GEMINI_KEYS = [k for k in [os.environ.get("GEMINI_API_KEY")] if k]
GROQ_KEYS = [k for k in [os.environ.get("GROQ_API_KEY_1"), os.environ.get("GROQ_API_KEY_2")] if k]

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

def call_gemini_api(key, system_prompt, user_content):
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
    
    for model in models_to_try:
        try:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode('utf-8'),
                headers={
                    'Content-Type': 'application/json',
                    'x-goog-api-key': key
                },
                method='POST'
            )
            with urllib.request.urlopen(req, timeout=6) as response:
                res_body = response.read().decode('utf-8')
                res_json = json.loads(res_body)
                text = res_json['candidates'][0]['content']['parts'][0]['text']
                return json.loads(text)
        except Exception as e:
            last_error = e

    raise last_error or Exception("Gemini API call failed")

def call_groq_api(key, system_prompt, user_content):
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
    
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode('utf-8'),
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {key}'
        },
        method='POST'
    )
    
    with urllib.request.urlopen(req, timeout=6) as response:
        res_body = response.read().decode('utf-8')
        res_json = json.loads(res_body)
        text = res_json['choices'][0]['message']['content']
        return json.loads(text)

def execute_ai_with_failover(system_prompt, user_content):
    """Execute AI request with multi-key and multi-provider automatic failover rotation."""
    providers = []
    
    # Add Gemini keys
    for k in GEMINI_KEYS:
        if k and not k.startswith("YOUR_"):
            providers.append(("Gemini", k, call_gemini_api))
            
    # Add Groq keys
    for i, k in enumerate(GROQ_KEYS):
        if k and not k.startswith("YOUR_"):
            providers.append((f"Groq-Key-{i+1}", k, call_groq_api))
            
    errors = []
    for provider_name, key, func in providers:
        try:
            logging.info(f"Attempting AI request with provider: {provider_name}")
            result = func(key, system_prompt, user_content)
            logging.info(f"Successfully generated response via {provider_name}")
            return result, provider_name
        except Exception as e:
            logging.warning(f"Provider {provider_name} failed: {e}. Trying next available key in pool...")
            errors.append(f"{provider_name}: {str(e)}")
            
    raise Exception(f"All AI API keys exhausted/failed. Errors: {'; '.join(errors)}")

class SafeRouteAiBackendHandler(BaseHTTPRequestHandler):
    """HTTP Request Handler for SafeRoute AI Explanation Backend."""
    
    def _send_json_response(self, status_code, data):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_GET(self):
        if self.path == '/api/health':
            health_status = {
                "status": "healthy",
                "service": "SafeRoute AI Backend Proxy",
                "gemini_keys_available": len([k for k in GEMINI_KEYS if k]),
                "groq_keys_available": len([k for k in GROQ_KEYS if k]),
                "active_failover_pool": "Gemini -> Groq-Key-1 -> Groq-Key-2"
            }
            self._send_json_response(200, health_status)
        else:
            self._send_json_response(404, {"error": "Endpoint not found"})

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body_bytes = self.rfile.read(content_length)
        
        try:
            req_data = json.loads(body_bytes.decode('utf-8')) if body_bytes else {}
        except Exception:
            self._send_json_response(400, {"error": "Invalid JSON payload"})
            return

        if self.path == '/api/explain-route':
            self._handle_explain_route(req_data)
        elif self.path == '/api/explain-comparison':
            self._handle_explain_comparison(req_data)
        elif self.path == '/api/explain-hazard':
            self._handle_explain_hazard(req_data)
        elif self.path == '/api/answer-question':
            self._handle_answer_question(req_data)
        elif self.path == '/api/trip-insight':
            self._handle_trip_insight(req_data)
        else:
            self._send_json_response(404, {"error": "Endpoint not found"})

    def _handle_explain_route(self, data):
        score = data.get('safety_score', 100)
        distance_km = data.get('distance_km', '0.0')
        duration_min = data.get('duration_min', 0)
        signals = data.get('signals', [])
        
        user_content = f"""Route Safety Score: {score}/100
Route Distance: {distance_km} km
Route Duration: {duration_min} minutes
Verified Signals: {json.dumps(signals)}"""

        self._execute_and_respond(user_content)

    def _handle_explain_comparison(self, data):
        candidates = data.get('candidates', [])
        user_content = f"Route Candidates Comparison:\n{json.dumps(candidates, indent=2)}"
        self._execute_and_respond(user_content)

    def _handle_explain_hazard(self, data):
        hazard_type = data.get('hazard_type', 'hazard')
        distance_m = data.get('distance_m', 0)
        description = data.get('description', '')
        confidence = data.get('confidence', 1.0)
        
        user_content = f"""Single Hazard Inspection:
Hazard Type: {hazard_type}
Distance from route: {distance_m} meters
Reported Description: <untrusted_content>{description}</untrusted_content>
Confidence Level: {confidence}"""

        self._execute_and_respond(user_content)

    def _handle_answer_question(self, data):
        question = data.get('question', '')
        nav_state = data.get('navigation_state', {})
        
        user_content = f"""User Question: <untrusted_content>{question}</untrusted_content>
Current Navigation State & Context:
{json.dumps(nav_state, indent=2)}"""

        self._execute_and_respond(user_content)

    def _handle_trip_insight(self, data):
        trip_summary = data.get('trip_summary', {})
        user_content = f"Completed Trip Metrics:\n{json.dumps(trip_summary, indent=2)}"
        self._execute_and_respond(user_content)

    def _execute_and_respond(self, user_content):
        try:
            response_json, provider_used = execute_ai_with_failover(SYSTEM_PROMPT, user_content)
            response_json['provider_used'] = provider_used
            self._send_json_response(200, response_json)
        except Exception as e:
            logging.error(f"Error processing AI request: {e}")
            error_response = {
                "error": True,
                "message": str(e),
                "fallback_available": True
            }
            self._send_json_response(500, error_response)

def run_server():
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, SafeRouteAiBackendHandler)
    logging.info(f"SafeRoute AI Backend Server running on port {PORT}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logging.info("Stopping server...")
        httpd.server_close()

if __name__ == '__main__':
    run_server()
