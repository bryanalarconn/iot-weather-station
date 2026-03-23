/*
 * ============================================================
 *  WEATHER MONITORING STATION
 *  Board    : Inland ESP32 DevKit
 *  Framework: Arduino (PlatformIO)
 * ============================================================
 *
 *  WIRING REFERENCE
 *  ----------------
 *  DHT11 Temperature & Humidity Sensor:
 *    VCC  → 3.3V
 *    GND  → GND
 *    DATA → GPIO4   (add 10kΩ pull-up resistor to 3.3V)
 *
 *  BMP180 Barometric Pressure Sensor (I2C):
 *    VCC → 3.3V
 *    GND → GND
 *    SDA → GPIO21
 *    SCL → GPIO22
 *    Note: I2C address is fixed at 0x77
 *
 *  Photoresistor — voltage divider (pull-down config):
 *    3.3V → [Photoresistor] → GPIO34 → [10kΩ] → GND
 *    (Brighter light → higher ADC reading)
 *
 *  Potentiometer (high-temp alert threshold):
 *    Left  pin → GND
 *    Wiper pin → GPIO35
 *    Right pin → 3.3V
 *    (Wiper voltage linearly maps to 50–100 °F alert threshold)
 * ============================================================
 */

#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_BMP085.h>

// ---- Pin Assignments -----------------------------------------------
#define DHT_PIN       4
#define DHT_TYPE      DHT11
#define PHOTO_PIN     34   // ADC input — photoresistor voltage divider
#define POT_PIN       35   // ADC input — potentiometer wiper (alert threshold)

// ---- Tunable Constants ---------------------------------------------
#define READ_INTERVAL_MS   3000
#define PRESSURE_HISTORY   10
#define RAIN_DROP_HPA      2.0f
#define POT_TEMP_MIN_F     50.0f
#define POT_TEMP_MAX_F     100.0f

// ---- Peripheral Objects --------------------------------------------
DHT             dht(DHT_PIN, DHT_TYPE);
Adafruit_BMP085 bmp;

// ---- Sensor Values -------------------------------------------------
float tempC       = 0.0f;
float tempF       = 0.0f;
float humidity    = 0.0f;
float pressureHPa = 0.0f;
float heatIndexF  = 0.0f;
int   lightPct    = 0;

// ---- Pressure Trend (ring buffer) ----------------------------------
float   pressureHistory[PRESSURE_HISTORY];
uint8_t pressureIdx  = 0;
bool    pressureFull = false;
bool    rainLikely   = false;

// ---- Timing --------------------------------------------------------
unsigned long lastReadMs = 0;

// ---- Forward Declarations ------------------------------------------
void readSensors();
void updatePressureTrend(float hPa);
void checkThresholdAlert();
void printReadings();

// ====================================================================
//  SETUP
// ====================================================================
void setup() {
    Serial.begin(115200);

    dht.begin();

    if (!bmp.begin()) {
        Serial.println("[WARN] BMP180 not detected — check wiring.");
    }

    memset(pressureHistory, 0, sizeof(pressureHistory));
    Serial.println("[INFO] Weather station ready.");
}

// ====================================================================
//  MAIN LOOP
// ====================================================================
void loop() {
    unsigned long now = millis();
    if (now - lastReadMs >= READ_INTERVAL_MS) {
        lastReadMs = now;

        readSensors();
        checkThresholdAlert();
        printReadings();
    }
}

// ====================================================================
//  SENSOR READING
// ====================================================================
void readSensors() {
    // --- DHT11 ---
    float h = dht.readHumidity();
    float c = dht.readTemperature();
    if (!isnan(h) && !isnan(c)) {
        humidity   = h;
        tempC      = c;
        tempF      = dht.readTemperature(true);
        heatIndexF = dht.computeHeatIndex(tempF, humidity);
    } else {
        Serial.println("[WARN] DHT11 read failed — retaining previous values.");
    }

    // --- BMP180 ---
    pressureHPa = bmp.readPressure() / 100.0f;
    updatePressureTrend(pressureHPa);

    // --- Photoresistor ---
    lightPct = (int)map(analogRead(PHOTO_PIN), 0, 4095, 0, 100);
}

// ====================================================================
//  PRESSURE TREND — ring buffer
// ====================================================================
void updatePressureTrend(float hPa) {
    pressureHistory[pressureIdx] = hPa;
    pressureIdx = (pressureIdx + 1) % PRESSURE_HISTORY;
    if (pressureIdx == 0) pressureFull = true;

    if (pressureFull) {
        float oldest = pressureHistory[pressureIdx];
        float newest = pressureHistory[(pressureIdx + PRESSURE_HISTORY - 1) % PRESSURE_HISTORY];
        rainLikely = (oldest - newest) > RAIN_DROP_HPA;
    }
}

// ====================================================================
//  THRESHOLD ALERT — reads potentiometer, logs warning if temp exceeds
// ====================================================================
void checkThresholdAlert() {
    int raw = analogRead(POT_PIN);
    float thresholdF = POT_TEMP_MIN_F +
                       ((float)raw / 4095.0f) * (POT_TEMP_MAX_F - POT_TEMP_MIN_F);

    if (tempF > thresholdF) {
        Serial.printf("[ALERT] Temp %.1fF exceeds threshold %.1fF!\n", tempF, thresholdF);
    }
}

// ====================================================================
//  SERIAL OUTPUT
// ====================================================================
void printReadings() {
    Serial.printf("[Sensors] %.1fF / %.1fC  Hum:%.1f%%  "
                  "Pres:%.1f hPa  Light:%d%%  HI:%.1fF  Rain:%s\n",
                  tempF, tempC, humidity, pressureHPa, lightPct, heatIndexF,
                  rainLikely ? "LIKELY" : "no");
}
