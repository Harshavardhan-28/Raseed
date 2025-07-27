# main.py

import functions_framework
import vertexai
import json
import os
import base64
from vertexai.generative_models import GenerativeModel, Part, GenerationConfig
from datetime import datetime
import pytz

# Get project ID and location from environment variables
PROJECT_ID = os.environ.get("GCLOUD_PROJECT")
LOCATION = "europe-west1"  # Must match the function's region

# Initialize Vertex AI client
vertexai.init(project=PROJECT_ID, location=LOCATION)

# Load the Gemini 2.5 Pro model
model = GenerativeModel("gemini-2.5-pro")

# Define the strict JSON schema based on your requirements
output_schema = {
    "type": "object",
    "properties": {
        "original_language": {"type": "string", "description": "The original language spoken in the audio, e.g., 'en', 'es'"},
        "receipt_no": {"type": "string", "description": "The receipt or transaction number, if mentioned."},
        "store_name": {"type": "string", "description": "The name of the store or vendor."},
        "date_and_time": {
            "type": "string",
            "format": "date-time",
            "description": "The transaction date and time in YYYY-MM-DDTHH:MM:SS format. Infer from context if not explicitly stated."
        },
        "currency": {"type": "string", "description": "The currency of the transaction, e.g., 'INR', 'USD', 'EUR'."},
        "category": {
            "type": "string",
            "description": "The overall category for the receipt.",
            "enum": ["Groceries", "Electronics", "Travel", "Restaurants", "Utilities", "Entertainment", "Other"]
        },
        "total_amount": {"type": "number", "description": "The final total amount paid."},
        "tax_amount": {"type": "number", "description": "The total tax amount, if mentioned."},
        "line_items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "The name of the purchased item."},
                    "price_per_quantity": {"type": "number", "description": "The price for a single unit of the item."},
                    "quantity": {"type": "integer", "description": "The quantity of the item purchased."},
                    "price": {"type": "number", "description": "The total price for this line item (quantity * price_per_quantity)."},
                    "category": {
                        "type": "string",
                        "description": "The specific category for this line item.",
                        "enum": ["Groceries", "Electronics", "Travel", "Restaurants", "Utilities", "Entertainment", "Other"]
                    },
                    "isFood": {"type": "boolean", "description": "True if the item is a food product."},
                    "isRecurring": {"type": "boolean", "description": "True if this is a recurring expense like a subscription."},
                    "isWarranty": {"type": "boolean", "description": "True if a warranty was purchased for this item."},
                },
                "required": ["name", "quantity", "price"]
            }
        }
    },
    "required": ["store_name", "date_and_time", "currency", "category", "total_amount", "line_items"]
}


@functions_framework.http
def parse_audio_bill_direct(request):
    """HTTP Cloud Function to parse spoken phrases directly from an audio file into a structured bill JSON."""

    # Set CORS headers for preflight requests
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    }

    if request.method == "OPTIONS":
        return ("", 204, headers)

    if request.method != "POST":
        return ("Method Not Allowed", 405, headers)

    request_json = request.get_json(silent=True)
    if not request_json or "audio" not in request_json:
        return ("Bad Request: Missing base64 encoded audio in the request body.", 400, headers)

    try:
        # --- Step 1: Prepare Audio and Prompt for Gemini ---
        print("Decoding audio data...")
        audio_data = base64.b64decode(request_json["audio"])

        audio_part = Part.from_data(
            data=audio_data,
            mime_type="audio/wav"  # Set the MIME type for your audio format
        )

        # Use dynamic date/time (UTC)
        now_utc = datetime.now(pytz.utc)
        current_datetime_str = now_utc.strftime('%Y-%m-%dT%H:%M:%S')

        prompt = f"""
        You are a highly intelligent financial assistant API. Your task is to listen to the following audio from a user and convert it into a structured JSON bill.

        Follow these rules carefully:
        1.  **Date and Time**: If the user doesn't specify a date, use the current date and time provided: **{current_datetime_str}**.
        2.  **Category**: Analyze the items to determine the most appropriate overall `category` for the receipt. Do the same for each line item.
        3.  **Calculations**: If the user says "3 tomatoes for 30 rupees", `price_per_quantity` should be 10, `quantity` should be 3, and `price` should be 30.
        4.  **Booleans**: Infer the boolean values (`isFood`, `isRecurring`, `isWarranty`) from the item's description and context.
        5.  **Strict Compliance**: Adhere strictly to the provided JSON schema. All required fields must be present.
        """

        # --- Step 2: Call Gemini and Get Structured JSON ---
        print("Extracting structured JSON from audio...")

        generation_config = GenerationConfig(
            response_mime_type="application/json",
            response_schema=output_schema,
            temperature=0.0  # For maximum consistency
        )

        gemini_response = model.generate_content(
            [audio_part, prompt],
            generation_config=generation_config,
        )

        data = json.loads(gemini_response.text)
        print(f"Successfully parsed data: {json.dumps(data, indent=2)}")
        return (json.dumps(data), 200, headers)

    except Exception as e:
        print(f"Error processing audio: {e}")
        error_payload = {
            "error": "Failed to parse the audio bill.",
            "details": str(e)
        }
        return (json.dumps(error_payload), 500, headers)
