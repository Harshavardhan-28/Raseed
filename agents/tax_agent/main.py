# main.py
import os
import uvicorn
import firebase_admin
from firebase_admin import credentials
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from dotenv import load_dotenv
from datetime import datetime, timedelta

# Load environment variables from .env
load_dotenv()

# --- Agent Imports ---
from src.agents.reimbursement_scout_agent import ReimbursementScoutAgent
from src.agents.tax_analyst_agent import TaxAnalystAgent

# --- Firebase Initialization ---
cred = credentials.Certificate("service-account-key.json")
firebase_admin.initialize_app(cred)

# --- FastAPI App Initialization ---
app = FastAPI()

# --- CORS Configuration (to allow browser access) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for local testing
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Define Request Body Model for Validation ---
class AnalyzeRequest(BaseModel):
    userId: str
    task: str
    timeframe: str

# --- Master Orchestrator Endpoint ---
@app.post("/analyze")
async def analyze(request: AnalyzeRequest):
    """
    Receives a request, selects the appropriate agent, and returns the result.
    """
    print(f"Received task: {request.task} for user: {request.userId} with timeframe: {request.timeframe}")

    # Calculate dates
    end_date = datetime.now()
    if request.timeframe == "last_30_days":
        start_date = end_date - timedelta(days=30)
    elif request.timeframe == "last_90_days":
        start_date = end_date - timedelta(days=90)
    else: # Default to "last_year"
        start_date = end_date - timedelta(days=365)
    
    try:
        if request.task == "find_reimbursements":
            agent = ReimbursementScoutAgent()
            result = agent.run(user_id=request.userId, start_date=start_date, end_date=end_date)
        elif request.task == "calculate_tax":
            agent = TaxAnalystAgent()
            result = agent.run(user_id=request.userId, start_date=start_date, end_date=end_date)
        else:
            raise HTTPException(status_code=400, detail="Invalid task specified.")
        
        return result
    except Exception as e:
        print(f"An error occurred: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- Serve the static frontend for testing ---
app.mount("/", StaticFiles(directory="public", html=True), name="static")


if __name__ == "__main__":
    print("\n🚀 Starting Python Agent Server...")
    print("👉 Your test interface will be available at http://localhost:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)