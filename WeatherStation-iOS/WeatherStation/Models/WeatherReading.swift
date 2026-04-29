import Foundation
import SwiftUI

// MARK: - Core model matching ESP32 JSON payload exactly
// Fields: temp_f, temp_c, humidity, pressure_hpa, heat_index_f,
//         light_pct, rain_likely

struct WeatherReading: Codable, Identifiable {
    var id = UUID()
    let temp_f: Double
    let temp_c: Double
    let humidity: Double
    let pressure_hpa: Double
    let heat_index_f: Double
    let light_pct: Double
    let rain_likely: Bool
    var timestamp: Date = Date()

    enum CodingKeys: String, CodingKey {
        case temp_f, temp_c, humidity, pressure_hpa
        case heat_index_f, light_pct, rain_likely
    }
}

// MARK: - Comfort zone logic (mirrors the prototype's getPct / getMode)
enum ComfortZone: String {
    case cold   = "Cold"
    case good   = "Comfortable"
    case warm   = "Warm"
    case hot    = "Hot"
    case rain   = "Rainy"

    static func from(tempF: Double, rainLikely: Bool) -> ComfortZone {
        if rainLikely { return .rain }
        if tempF < 60  { return .cold }
        if tempF <= 80 { return .good }
        if tempF <= 90 { return .warm }
        return .hot
    }

    var color: Color {
        switch self {
        case .cold: return Color(hex: "#4a9eff")
        case .good: return Color(hex: "#b5d45a")
        case .warm: return Color(hex: "#f5c542")
        case .hot:  return Color(hex: "#ff5e3a")
        case .rain: return Color(hex: "#60a5fa")
        }
    }

    var emoji: String {
        switch self {
        case .cold: return "❄️"
        case .good: return "🌿"
        case .warm: return "☀️"
        case .hot:  return "🔥"
        case .rain: return "🌧️"
        }
    }

    var skyColors: [Color] {
        switch self {
        case .cold: return [Color(hex: "#0a1628"), Color(hex: "#1a3a5c"), Color(hex: "#4a9eff")]
        case .good: return [Color(hex: "#0d1f0a"), Color(hex: "#1a3d1a"), Color(hex: "#5aad6e")]
        case .warm: return [Color(hex: "#1a0d00"), Color(hex: "#3d1f00"), Color(hex: "#f5c542")]
        case .hot:  return [Color(hex: "#1a0000"), Color(hex: "#4a0a0a"), Color(hex: "#ff6b2b")]
        case .rain: return [Color(hex: "#0a0d1a"), Color(hex: "#1a1f3d"), Color(hex: "#6b8aaa")]
        }
    }

    /// 0–100 position on the comfort zone track
    func trackPercent(tempF: Double) -> Double {
        if tempF < 60  { return max(2, (tempF - 40) / 20 * 26) }
        if tempF <= 80 { return 26 + (tempF - 60) / 20 * 30 }
        if tempF <= 90 { return 56 + (tempF - 80) / 10 * 24 }
        return min(95, 80 + (tempF - 90) / 10 * 15)
    }

    var zenQuotes: [String] {
        switch self {
        case .cold: return ["Cold air, clear mind.", "Bundle up, it's beautiful."]
        case .good: return ["The air is just right.", "Breathe easy today.", "All is well outside."]
        case .warm: return ["Stay hydrated out there.", "Summer is saying hello."]
        case .hot:  return ["Stay cool. Seriously.", "The sun means business."]
        case .rain: return ["Rain is on its way — how poetic.", "The clouds are gathering."]
        }
    }
}

// MARK: - History model
struct HistoryEntry: Identifiable {
    let id = UUID()
    let reading: WeatherReading
    let timestamp: Date
}

// MARK: - Alert log model
struct AlertEvent: Identifiable {
    let id = UUID()
    let type: AlertType
    let tempF: Double
    let timestamp: Date

    enum AlertType {
        case overTemp, rain, highHumidity, offline
        var label: String {
            switch self {
            case .overTemp:     return "Over-temp triggered"
            case .rain:         return "Rain predicted"
            case .highHumidity: return "High humidity"
            case .offline:      return "Sensor offline"
            }
        }
        var iconName: String {
            switch self {
            case .overTemp:     return "thermometer.high"
            case .rain:         return "cloud.rain"
            case .highHumidity: return "drop"
            case .offline:      return "wifi.slash"
            }
        }
        var color: Color {
            switch self {
            case .overTemp:     return Color(hex: "#f5c542")
            case .rain:         return Color(hex: "#93c5fd")
            case .highHumidity: return Color(hex: "#93c5fd")
            case .offline:      return Color(hex: "#b5d45a")
            }
        }
    }
}

// MARK: - Color from hex helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
