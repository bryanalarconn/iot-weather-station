# IoT Weather Station

An ESP32-based weather monitoring station that reads temperature, humidity, barometric pressure, and light level — then posts the data to a Flask backend hosted on Google Cloud Run, where it is stored in Firestore.

---

## Hardware

| Component | Purpose |
|---|---|
| Inland ESP32 DevKit | Microcontroller |
| DHT11 | Temperature & humidity |
| BMP180 | Barometric pressure |
| Photoresistor | Light level |

---

## Wiring

### DHT11 (Temperature & Humidity)
| DHT11 Pin | ESP32 Pin |
|---|---|
| VCC | 3.3V |
| GND | GND |
| DATA | GPIO 4 |

> Add a 10kΩ pull-up resistor between DATA and 3.3V.

### BMP180 (Barometric Pressure) — I2C
| BMP180 Pin | ESP32 Pin |
|---|---|
| VCC | 3.3V |
| GND | GND |
| SDA | GPIO 21 |
| SCL | GPIO 22 |

> I2C address is fixed at 0x77.

### Photoresistor (Light Level) — voltage divider
```
3.3V → [Photoresistor] → GPIO 34 → [10kΩ] → GND
```
Higher light = higher ADC reading = higher light percentage.

---

## Setup

### Firmware

#### 1. Install PlatformIO
Install the [PlatformIO IDE extension](https://platformio.org/install/ide?install=vscode) for VS Code, or use the PlatformIO CLI.

#### 2. Configure credentials
Open `firmware/include/config.h` and fill in your details:

```cpp
#define WIFI_SSID   "your_wifi_name"
#define WIFI_PASS   "your_wifi_password"
#define POST_URL    "https://your-backend.run.app/data"
```

#### 3. Build and flash
```bash
pio run --target upload
```

#### 4. Monitor serial output
```bash
pio device monitor --baud 115200
```

### Backend

The backend is a Flask app containerized with Docker and deployed to Google Cloud Run, with Firestore as the database.

#### Local development
```bash
cd backend
pip install -r requirements.txt
python app.py
```

#### Deploy to Cloud Run
```bash
gcloud run deploy --source backend/
```

> The service account running the container must have Firestore read/write permissions.

---

## How It Works

Every **30 seconds** the ESP32:
1. Reads all sensors
2. Prints a summary line to the serial monitor
3. POSTs a JSON payload to the backend over HTTPS

The backend validates the payload, enforces a **30-second rate limit** per device (by `device_id` or IP), and writes the reading to the `sensor_data` Firestore collection.

### Example serial output
```
[Sensors] 76.3F / 24.6C  Hum:58.2%  Pres:1014.5 hPa  Light:63%  HI:76.3F  Rain:no
[HTTP] POST https://your-backend.run.app/data
[HTTP] Response: 200
```

### JSON payload

```json
{
  "temp_f": 76.3,
  "temp_c": 24.6,
  "humidity": 58.2,
  "pressure_hpa": 1014.5,
  "heat_index_f": 76.3,
  "light_pct": 63,
  "rain_likely": false
}
```

### JSON fields explained

| Field | Description |
|---|---|
| `temp_f` / `temp_c` | Temperature in Fahrenheit and Celsius |
| `humidity` | Relative humidity percentage |
| `pressure_hpa` | Barometric pressure in hectopascals |
| `heat_index_f` | Feels-like temperature (NOAA formula, factors in humidity) |
| `light_pct` | Light level 0–100% |
| `rain_likely` | `true` if pressure dropped more than 2 hPa over the last 10 readings |

---

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/data` | Ingest a sensor reading |
| `GET` | `/latest` | Return the most recent reading |
| `GET` | `/` | Health check |

---

## Configuration Reference

All tunable firmware settings live in `firmware/include/config.h`.

| Constant | Default | Description |
|---|---|---|
| `READ_INTERVAL_MS` | 5000 | How often sensors are sampled (milliseconds) |
| `PRESSURE_HISTORY` | 10 | Number of pressure readings tracked for rain prediction |
| `RAIN_DROP_HPA` | 2.0 | Pressure drop (hPa) that triggers `rain_likely = true` |

---

## iOS App

A native SwiftUI app lives in `WeatherStation-iOS/`. It connects to the backend's `/latest` endpoint to display the most recent sensor reading.

---

## Libraries

### Firmware
| Library | Purpose |
|---|---|
| Adafruit DHT Sensor Library | DHT11 temperature & humidity |
| Adafruit BMP085 Library | BMP180 barometric pressure |
| Adafruit Unified Sensor | Shared sensor abstraction |
| ArduinoJson | JSON serialization |

### Backend
| Package | Purpose |
|---|---|
| Flask | HTTP server |
| gunicorn | Production WSGI server |
| firebase-admin | Firestore client |
