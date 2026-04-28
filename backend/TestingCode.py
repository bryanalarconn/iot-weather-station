import requests,random

URL = "https://esp32-api-473950836517.us-west1.run.app/data"  
API_KEY = "weather-time"

payload = {
    "temp_f": 77.3,
    "temp_c": 24.6,
    "humidity": 56.7,
    "pressure_hpa": 1014.9,
    "heat_index_f": 76.3,
    "light_pct": 0,
    "rain_likely": False
    #"alert_threshold_f": 50.0,
    #"threshold_exceeded": True
}

headers = {
    "Content-Type": "application/json"
}


def send_payload():
    response = requests.post(URL, json=payload, headers=headers)

    print("Status:", response.status_code)
    print("Response:", response.text)

def clamp(n,smallest,largest):
    return max(smallest, min(n,largest))

send_payload()

#while True:
#    payload["temp_f"] = clamp(payload["temp_f"] + random.uniform(-1.0,1.0),50,100)
#    payload["temp_c"] = (payload["temp_f"] -32.0) * 5.0 / 9.0
#    payload["humidity"] = clamp(payload["humidity"] + random.uniform(-1.0,1.0),0,100)
#    payload["pressure_hpa"] = clamp(payload["pressure_hpa"] + random.uniform(-0.5,0.5),1000,1100)
#    payload["heat_index_f"] = payload["temp_f"] - 1.0