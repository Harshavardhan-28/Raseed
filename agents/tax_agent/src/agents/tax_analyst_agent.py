# src/agents/tax_analyst_agent.py
from src.tools import firestore_tool

class TaxAnalystAgent:
    def run(self, user_id: str, start_date, end_date) -> dict:
        print(f"[Agent] Running Tax Analyst for user {user_id}...")
        receipts = firestore_tool.query_receipts_by_date_range(user_id, start_date, end_date)
        total_tax = 0.0
        tax_by_category = {}

        for receipt in receipts:
            tax = float(receipt.get("tax_amount", 0))
            total_tax += tax
            
            pre_tax_total = float(receipt.get("total_amount", 0)) - tax
            if pre_tax_total <= 0:
                continue

            for item in receipt.get("line_items", []):
                item_category = item.get("category", "Uncategorized")
                item_price = float(item.get("price", 0))
                item_proportion = item_price / pre_tax_total
                attributed_tax = tax * item_proportion
                
                tax_by_category[item_category] = tax_by_category.get(item_category, 0) + attributed_tax

        category_breakdown = [
            {"category": name, "tax_amount": round(amount, 2)}
            for name, amount in tax_by_category.items()
        ]

        print(f"[Agent] Calculated total tax: {total_tax}.")
        return {
            "report_type": "Tax Report",
            "total_tax": round(total_tax, 2),
            "category_breakdown": category_breakdown
        }