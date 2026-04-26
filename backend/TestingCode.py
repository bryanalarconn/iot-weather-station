import requests

URL = "https://esp32-api-473950836517.us-west1.run.app/data"  
API_KEY = "weather-time"

payload = {
    "temp_f": 77.3,
    "temp_c": 24.6,
    "humidity": 56.7,
    "pressure_hpa": 1014.9,
    "heat_index_f": 76.3,
    "light_pct": 0,
    "rain_likely": False,
    "alert_threshold_f": 50.0,
    "threshold_exceeded": True
}

headers = {
    "Content-Type": "application/json"
}

response = requests.post(URL, json=payload, headers=headers)

print("Status:", response.status_code)
print("Response:", response.text)

