import datetime
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

def query_receipts_by_date_range(user_id: str, start_date: datetime.datetime, end_date: datetime.datetime) -> list:
    """Queries receipts for a specific user within a date range."""
    try:
        db = firestore.client()
        receipts_ref = db.collection("receipts")
        query = receipts_ref.where(filter=FieldFilter("user_id", "==", user_id)) \
                    .where(filter=FieldFilter("purchase_date", ">=", start_date)) \
                    .where(filter=FieldFilter("purchase_date", "<=", end_date))
        
        docs = query.stream()
        
        receipts = []
        for doc in docs:
            receipt_data = doc.to_dict()
            receipt_data['id'] = doc.id
            receipts.append(receipt_data)
            
        print(f"[Firestore Tool] Found {len(receipts)} receipts for user {user_id}.")
        return receipts
    except Exception as e:
        print(f"Error querying Firestore: {e}")
        raise