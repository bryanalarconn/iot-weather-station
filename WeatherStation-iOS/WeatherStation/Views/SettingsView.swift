import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SettingsView  (Screen 4)
// ─────────────────────────────────────────────────────────────────────────────

struct SettingsView: View {
    @ObservedObject var vm: WeatherViewModel
    @State private var zenEnabled = true
    @State private var connectionStatus: ConnectionStatus = .pending

    enum ConnectionStatus { case pending, connected, failed }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0a0f1a"), Color(hex: "#101828"), Color(hex: "#0a1020")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Orbs
            Circle()
                .fill(RadialGradient(colors: [Color(hex: "#1a2d5a").opacity(0.5), .clear],
                                     center: .center, startRadius: 0, endRadius: 120))
                .frame(width: 240, height: 240)
                .offset(x: 80, y: -60)
                .blur(radius: 2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Settings")
                            .font(WT.display(28, weight: .bold))
                            .foregroundStyle(WT.textPrimary)
                        Text("Station configuration")
                            .font(WT.body(11))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .padding(.bottom, 20)

                    // ── Station group
                    SettingGroup(title: "Station") {
                        SettingRow(label: "Name",          value: "Backyard Station")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "Location",      value: "Los Angeles, CA")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "Read interval", value: "5 seconds")
                        Divider().background(Color.white.opacity(0.06))
                        HStack {
                            Text("Last seen")
                                .font(WT.body(14, weight: .medium))
                                .foregroundStyle(WT.textPrimary)
                            Spacer()
                            Text(vm.lastUpdated.map {
                                $0.formatted(date: .omitted, time: .standard)
                            } ?? "—")
                                .font(WT.body(13))
                                .foregroundStyle(vm.isConnected ? WT.accent.opacity(0.8) : Color.white.opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.07))
                    }
                    .padding(.bottom, 10)

                    // ── Display group
                    SettingGroup(title: "Display") {
                        SettingRow(label: "Temperature unit", value: "°F + °C")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "Pressure unit",    value: "hPa")
                        Divider().background(Color.white.opacity(0.06))
                        HStack {
                            Text("Zen quotes")
                                .font(WT.body(14, weight: .medium))
                                .foregroundStyle(WT.textPrimary)
                            Spacer()
                            Toggle("", isOn: $zenEnabled)
                                .labelsHidden()
                                .tint(WT.accent)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.07))
                    }
                    .padding(.bottom, 10)

                    // ── Hardware group
                    SettingGroup(title: "Hardware (ESP32)") {
                        SettingRow(label: "MCU",          value: "Inland ESP32 DevKit")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "DHT11 pin",   value: "GPIO 4")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "BMP180 I²C",  value: "0x77")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "Photoresistor", value: "GPIO 34")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "Pot threshold", value: "GPIO 35")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "Rain sensitivity", value: "2 hPa / 30s")
                    }
                    .padding(.bottom, 10)

                    // ── Cloud group
                    SettingGroup(title: "Cloud") {
                        SettingRow(
                            label: "Google Cloud Run",
                            value: "Pending setup",
                            valueColor: WT.accent.opacity(0.7)
                        )
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "Firestore",    value: "Not configured")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "API endpoint", value: "Not configured")
                        Divider().background(Color.white.opacity(0.06))
                        SettingRow(label: "Auth token",   value: "Not set")
                    }
                    .padding(.bottom, 10)

                    // ── Connection status card
                    GlassCard {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(vm.isConnected ? WT.accent : Color(hex: "#ff5e3a"))
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vm.isConnected ? "Station online" : "Station offline")
                                    .font(WT.body(13, weight: .semibold))
                                    .foregroundStyle(WT.textPrimary)
                                Text(vm.isConnected
                                     ? "Receiving data from ESP32"
                                     : "Check Wi-Fi and POST_URL in config.h")
                                    .font(WT.body(11))
                                    .foregroundStyle(WT.textMuted)
                            }
                            Spacer()
                        }
                    }
                    .padding(.bottom, 10)

                    // ── Version footer
                    VStack(spacing: 2) {
                        Text("ESP32 Weather Station · v0.1.0")
                            .font(WT.body(11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.2))
                        Text("PlatformIO · Arduino · DHT11 · BMP180 · ArduinoJson")
                            .font(WT.body(10))
                            .foregroundStyle(Color.white.opacity(0.12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SettingGroup  (grouped section like iOS Settings.app)
// ─────────────────────────────────────────────────────────────────────────────

struct SettingGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(WT.body(10, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(Color.white.opacity(0.3))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

#Preview {
    SettingsView(vm: WeatherViewModel())
}
