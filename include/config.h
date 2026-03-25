#pragma once

//  WIFI CREDENTIALS 
#define WIFI_SSID   "Your_SSID"
#define WIFI_PASS   "Your_PASSWORD"

//  HTTP ENDPOINT  
#define POST_URL    "https://your-server.example.com/weather"

//  GPIO PINS
#define DHT_PIN     4       // DHT11 data line
#define DHT_TYPE    DHT11
#define PHOTO_PIN   34      // Photoresistor ADC input
#define POT_PIN     35      // Potentiometer ADC input

//  SENSOR SETTINGS
#define READ_INTERVAL_MS    5000UL  // How often to sample sensors (ms)

#define PRESSURE_HISTORY    10      // Number of readings in the ring buffer
#define RAIN_DROP_HPA       2.0f    // hPa drop over the window → rain likely

//  POTENTIOMETER TEMP THRESHOLD RANGE
#define POT_TEMP_MIN_F      50.0f   // Threshold at pot = 0 %
#define POT_TEMP_MAX_F      100.0f  // Threshold at pot = 100 %
