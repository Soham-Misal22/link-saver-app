
import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load env variables
load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print("Error: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
    exit(1)

supabase: Client = create_client(url, key)

def fetch_logs():
    try:
        response = supabase.table("debug_events") \
            .select("*") \
            .order("created_at", desc=True) \
            .limit(10) \
            .execute()
        
        data = response.data
        
        # Print events
        print(f"Found {len(data)} events (showing last 10 chronologically):\n")
        # Reverse to show chronological order (Oldest -> Newest)
        for event in reversed(data[:10]): 
            print(f"[{event.get('created_at')}] {event.get('stage')}")
            print(f"Payload: {event.get('payload')}")
            if event.get('error'):
                print(f"ERROR: {event.get('error')}")
            print("-" * 40)

    except Exception as e:
        print(f"Error fetching logs: {e}")

if __name__ == "__main__":
    fetch_logs()
