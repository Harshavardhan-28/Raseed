# File: MY_RECIPE_AGENT/recipe_agent/tools.py
import firebase_admin
from firebase_admin import credentials, firestore
from google.adk.tools.tool_context import ToolContext
from datetime import datetime, timedelta, timezone
import os

# --- Firebase Initialization ---
try:
    if not firebase_admin._apps:
        key_file = "turing-runner-466506-n4-3556d090e0f3.json"
        if not os.path.exists(key_file):
            raise FileNotFoundError(f"CRITICAL ERROR: Firebase key file '{key_file}' not found.")
        cred = credentials.Certificate(key_file)
        firebase_admin.initialize_app(cred)
except ValueError:
    pass

db = firestore.client()

def fetch_groceries_from_firebase(user_id: str, time_period_days: int) -> dict:
    """Fetches a list of groceries for a specific user within a past number of days."""
    try:
        now = datetime.now(timezone.utc)
        start_date = now - timedelta(days=time_period_days)
        groceries_ref = db.collection('food')
        query = groceries_ref.where('userId', '==', user_id).where('purchaseDate', '>=', start_date)
        docs = query.stream()
        grocery_list = list(set([doc.to_dict().get('name').lower() for doc in docs if doc.to_dict().get('name')]))
        if not grocery_list:
            return {"status": "success", "groceries": [], "message": "No groceries found."}
        return {"status": "success", "groceries": grocery_list}
    except Exception as e:
        return {"status": "error", "error_message": f"Database query failed. Ensure Firestore index is enabled. Error: {e}"}

def check_ingredient_availability(required_ingredients: list[str], available_groceries: list[str]) -> dict:
    """Checks which ingredients for a recipe are missing from the available groceries list."""
    required_lower = {item.lower() for item in required_ingredients}
    available_lower = {item.lower() for item in available_groceries}
    missing_items = list(required_lower - available_lower)
    if not missing_items:
        return {"status": "success", "all_available": True, "missing_items": []}
    else:
        return {"status": "success", "all_available": False, "missing_items": missing_items}

def add_to_google_wallet(items: list, user_id: str, tool_context: ToolContext) -> dict:
    """(MOCKED) Adds a list of shopping items to the user's Google Wallet."""
    return {"status": "success", "message": f"I have added {', '.join(items)} to your shopping list."}