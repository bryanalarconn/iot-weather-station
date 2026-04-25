import Foundation
import Combine
import SwiftUI

// MARK: - ViewModel
// Connects to Firestore via Firebase SDK.
// Replace the firestoreURL with your actual Cloud Run / Firestore REST endpoint.
// The ESP32 POSTs to POST_URL every 5s; we poll the latest doc every 3s.

@MainActor
final class WeatherViewModel: ObservableObject {

    // MARK: Published state
    @Published var current: WeatherReading?
    @Published var history: [WeatherReading] = []
    @Published var alertEvents: [AlertEvent] = []
    @Published var isConnected = false
    @Published var lastUpdated: Date?
    @Published var thresholdF: Double = 85.0

    // Derived
    var zone: ComfortZone {
        guard let r = current else { return .good }
        return ComfortZone.from(tempF: r.temp_f, rainLikely: r.rain_likely)
    }

    var zenQuote: String {
        zone.zenQuotes.randomElement() ?? ""
    }

    // MARK: Private
    private var timer: AnyCancellable?
    private let maxHistory = 30

    // ─── CONFIGURE THIS ────────────────────────────────────────────────────────
    // Your Cloud Run endpoint that returns the latest reading as JSON.
    // e.g. "https://your-cloud-run-service.run.app/latest"
    private let latestEndpoint = "https://YOUR_CLOUD_RUN_URL/latest"
    // ───────────────────────────────────────────────────────────────────────────

    // MARK: - Init
    init() {
        startPolling()
    }

    // MARK: - Polling (every 3 s to match prototype cadence)
    func startPolling() {
        timer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.fetchLatest() }
            }
    }

    func stopPolling() {
        timer?.cancel()
    }

    // MARK: - Fetch latest reading
    func fetchLatest() async {
        guard let url = URL(string: latestEndpoint) else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                isConnected = false
                return
            }
            let reading = try JSONDecoder().decode(WeatherReading.self, from: data)
            applyReading(reading)
        } catch {
            isConnected = false
            // In development, use simulatedReading() below
        }
    }

    // MARK: - Apply a new reading
    func applyReading(_ reading: WeatherReading) {
        // Threshold from potentiometer comes from the ESP32 payload
        thresholdF = reading.alert_threshold_f

        current = reading
        lastUpdated = Date()
        isConnected = true

        // Append to history (cap at maxHistory)
        history.append(reading)
        if history.count > maxHistory { history.removeFirst() }

        // Check for alert events
        checkAlerts(reading)
    }

    // MARK: - Alert checking
    private func checkAlerts(_ reading: WeatherReading) {
        if reading.threshold_exceeded {
            let event = AlertEvent(type: .overTemp, tempF: reading.temp_f, timestamp: Date())
            alertEvents.insert(event, at: 0)
        }
        if reading.rain_likely {
            let event = AlertEvent(type: .rain, tempF: reading.temp_f, timestamp: Date())
            alertEvents.insert(event, at: 0)
        }
        if reading.humidity > 85 {
            let event = AlertEvent(type: .highHumidity, tempF: reading.temp_f, timestamp: Date())
            alertEvents.insert(event, at: 0)
        }
        if alertEvents.count > 20 { alertEvents = Array(alertEvents.prefix(20)) }
    }

    // MARK: - History helpers
    var tempHistory: [Double] { history.map(\.temp_f) }
    var humHistory:  [Double] { history.map(\.humidity) }

    var high24h: Double { tempHistory.max() ?? 0 }
    var low24h:  Double { tempHistory.min() ?? 0 }
    var avgHum:  Double {
        guard !humHistory.isEmpty else { return 0 }
        return humHistory.reduce(0, +) / Double(humHistory.count)
    }

    var pressureTrend: String {
        guard history.count >= 2 else { return "Stable" }
        let delta = history.last!.pressure_hpa - history[history.count - 2].pressure_hpa
        if delta < -2.0 { return "Falling" }
        if delta > 2.0  { return "Rising" }
        return "Stable"
    }

    var rainEvents: [Date] {
        history.filter(\.rain_likely).compactMap { _ in Date() }
    }

    // MARK: - Simulated reading (development / preview)
    static func simulated() -> WeatherReading {
        WeatherReading(
            temp_f: Double.random(in: 62...95),
            temp_c: Double.random(in: 17...35),
            humidity: Double.random(in: 45...85),
            pressure_hpa: Double.random(in: 1008...1022),
            heat_index_f: Double.random(in: 62...98),
            light_pct: Double.random(in: 30...95),
            rain_likely: Bool.random(),
            alert_threshold_f: 85.0,
            threshold_exceeded: false
        )
    }
}
