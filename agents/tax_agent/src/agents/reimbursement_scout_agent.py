# src/agents/reimbursement_scout_agent.py
from src.tools import firestore_tool, vertex_ai_tool

REIMBURSABLE_CATEGORIES = ["Transport", "Cab", "Flights", "Work Related Food", "Mobile Bill", "Software", "Office Supplies", "Accommodation"]

class ReimbursementScoutAgent:
    def run(self, user_id: str, start_date, end_date) -> dict:
        print(f"[Agent] Running Reimbursement Scout for user {user_id}...")
        receipts = firestore_tool.query_receipts_by_date_range(user_id, start_date, end_date)
        potential_reimbursements = []

        for receipt in receipts:
            line_items = receipt.get("line_items", [])
            for item in line_items:
                # Use the Vertex AI tool to understand the item
                category = vertex_ai_tool.categorize_description(item.get("description", ""))
                
                if category in REIMBURSABLE_CATEGORIES:
                    potential_reimbursements.append({
                        "purchase_date": item.get("purchase_date").strftime('%Y-%m-%d'),
                        "description": item.get("description", "N/A"),
                        "amount": item.get("price", 0),
                        "category": category,
                        "receipt_no": receipt.get("parsed_receipt_no", "N/A"),
                    })

        print(f"[Agent] Found {len(potential_reimbursements)} potential reimbursements.")
        return {
            "report_type": "Reimbursement Report",
            "item_count": len(potential_reimbursements),
            "items": potential_reimbursements
        }