from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import firestore
from datetime import datetime,timedelta
from google.cloud.firestore import SERVER_TIMESTAMP
import os

app = Flask(__name__)

REQUIRED_FIELDS = {
    "temp_f": float,
    "temp_c": float,
    "humidity": float,
    "pressure_hpa": float,
    "heat_index_f": float,
    "light_pct": int,
    "rain_likely": bool,
    "alert_threshold_f": float,
    "threshold_exceeded": bool
}

if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()


API_KEY = os.environ.get("API_KEY", "dev-key")

@app.route("/data", methods=["POST"])
def receive_data():
    
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 400

    data = request.json

   
    identifier = data.get("device_id")

    if not identifier:
        identifier = request.headers.get("X-Forwarded-For", request.remote_addr)

    identifier = str(identifier)

    if is_rate_limited(identifier):
        return jsonify({"error": "Too many requests"}), 429
    
    for field, expected_type in REQUIRED_FIELDS.items():
        if field not in data:
            return jsonify({"error": f"Missing field: {field}"}), 400

        value = data[field]

        if expected_type == float:
            if not isinstance(value, (int, float)):
                return jsonify({"error": f"{field} must be a number"}), 400

        elif expected_type == int:
            if not isinstance(value, int):
                return jsonify({"error": f"{field} must be an integer"}), 400

        elif expected_type == bool:
            if not isinstance(value, bool):
                return jsonify({"error": f"{field} must be a boolean"}), 400
    
    data["timestamp"] = datetime.utcnow()

    db.collection("sensor_data").add(data)

    return jsonify({"status": "success"}), 200

def is_rate_limited(identifier, limit_seconds=5):
    try:
        doc_ref = db.collection("rate_limits").document(str(identifier))
        doc = doc_ref.get()

        now = datetime.utcnow()

        if doc.exists:
            last_time = doc.to_dict().get("last_request")

            if last_time:
                if hasattr(last_time, "replace"):
                    last_time = last_time.replace(tzinfo=None)

                if (now - last_time) < timedelta(seconds=limit_seconds):
                    return True
        
        doc_ref.set({"last_request": SERVER_TIMESTAMP})

        return False

    except Exception as e:
        print("Rate limit error:", e)
        return False 

@app.route("/")
def health():
    return "OK", 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)