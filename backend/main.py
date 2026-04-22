from flask import Flask, request, jsonify

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

@app.route("/weather", methods=["POST"])
def receive_weather():
    data = request.get_json()

    if not data:
        return jsonify({"error": "No JSON body received"}), 400

    for field, expected_type in REQUIRED_FIELDS.items():
        if field not in data:
            return jsonify({"error": f"Missing field: {field}"}), 400
        if not isinstance(data[field], expected_type):
            return jsonify({"error": f"Invalid type for field: {field}"}), 400

    print(f"[INFO] Received: {data}")
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)