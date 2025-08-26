# src/tools/vertex_ai_tool.py
import os
import vertexai
from vertexai.generative_models import GenerativeModel

# Initialize Vertex AI once
vertexai.init(project=os.getenv("GCP_PROJECT_ID"), location=os.getenv("GCP_REGION"))
model = GenerativeModel("gemini-1.0-pro")

CATEGORY_LIST = "Transport, Cab, Flights, Work Related Food, Mobile Bill, Software, Office Supplies, Accommodation, Healthcare, Medical Bill, Health Insurance, Charitable Donation, Education, Other"

def categorize_description(description: str) -> str:
    """Uses Vertex AI Gemini to categorize an expense description."""
    prompt = f"""Analyze the following expense item and classify it into one of these categories: {CATEGORY_LIST}.
    Respond with only the category name, nothing else.

    Expense: "{description}"
    """
    try:
        response = model.generate_content(prompt)
        category = response.text.strip().replace(".", "")
        print(f"[Vertex AI Tool] Categorized '{description}' as '{category}'")
        return category
    except Exception as e:
        print(f"Error with Vertex AI Tool: {e}")
        return "Other" # Fallback category