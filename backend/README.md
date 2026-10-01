# SafeRoute AI — FastAPI Backend Proxy

Production-ready, lightweight FastAPI proxy service for **SafeRoute AI**. Handles Google Gemini and Groq AI natural-language explanation requests with multi-key automatic failover, Pydantic input validation, CORS support, and local fallback compatibility.

---

## Architecture Principles

1. **AI Explanation Proxy Only**: All user authentication, database operations, hazard report storage, PostGIS spatial queries, OSRM routing, and Nominatim geocoding remain handled directly by Supabase and client services.
2. **Zero Hardcoded Secrets**: Secrets and API keys are read strictly from environment variables (`GEMINI_API_KEY`, `GROQ_API_KEY_1`, `GROQ_API_KEY_2`).
3. **Render Cloud Deployment Ready**: Listens on Render's dynamic `$PORT` environment variable and binds to `0.0.0.0`.

---

## Local Development & Testing

### 1. Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 2. Set Local Environment Variables (Optional)
```bash
# Windows PowerShell
$env:GEMINI_API_KEY="your_gemini_api_key_here"

# Linux / macOS
export GEMINI_API_KEY="your_gemini_api_key_here"
```

### 3. Run the Development Server
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 4. Test Health Endpoint
- **URL**: `http://localhost:8000/health` or `http://localhost:8000/api/health`
- **Method**: `GET`
- **Response**:
```json
{
  "status": "ok",
  "service": "SafeRoute AI API",
  "gemini_configured": true,
  "groq_configured": false
}
```

### 5. Run Unit Tests
```bash
pytest test_main.py
```

---

## Render Deployment Instructions

When deploying to [Render](https://render.com/):

1. **Create New Web Service**: Connect your Git repository.
2. **Root Directory**: `backend`
3. **Environment**: `Python 3`
4. **Build Command**: `pip install -r requirements.txt`
5. **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
6. **Environment Variables**:
   - `GEMINI_API_KEY`: *(Your Google Gemini API Key)*
   - `GROQ_API_KEY_1`: *(Optional Groq Failover Key 1)*
   - `GROQ_API_KEY_2`: *(Optional Groq Failover Key 2)*

---

## API Endpoints Overview

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Health check endpoint returning `{"status": "ok", "service": "SafeRoute AI API"}` |
| `POST` | `/api/explain-route` | Generates natural-language safety score rationale for a walking route candidate |
| `POST` | `/api/explain-comparison` | Generates comparative analysis for multiple walking candidate routes |
| `POST` | `/api/explain-hazard` | Generates detailed hazard inspection explanation for a single report |
| `POST` | `/api/answer-question` | Answers user contextual safety questions during navigation |
| `POST` | `/api/trip-insight` | Summarizes completed walking trip safety metrics |
