from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import firestore
from datetime import datetime
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
    
    #if request.headers.get("x-api-key") != API_KEY:
        #return jsonify({"error": "Unauthorized"}), 401

    data = request.json

   
    #required_fields = ["temp_f", "humidity"]
    #for field in required_fields:
        #if field not in data:
            #return jsonify({"error": f"Missing {field}"}), 400
    
    for field, expected_type in REQUIRED_FIELDS.items():
        if field not in data:
            return jsonify({"error": f"Missing field: {field}"}), 400
        if not isinstance(data[field], expected_type):
            return jsonify({"error": f"Invalid type for field: {field}"}), 400

    
    data["timestamp"] = datetime.utcnow()

    
    db.collection("sensor_data").add(data)

    return jsonify({"status": "success"}), 200


@app.route("/")
def health():
    return "OK", 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)