import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AlertsView  (Screen 3)
// ─────────────────────────────────────────────────────────────────────────────

struct AlertsView: View {
    @ObservedObject var vm: WeatherViewModel

    // Notification toggles (local UI state — wire to push notification manager)
    @State private var overTempOn    = true
    @State private var rainOn        = true
    @State private var highHumOn     = false
    @State private var offlineOn     = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1a0a00"), Color(hex: "#2d1500"), Color(hex: "#1a0d00")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Orbs
            Circle()
                .fill(RadialGradient(colors: [Color(hex: "#6b2200").opacity(0.6), .clear],
                                     center: .center, startRadius: 0, endRadius: 130))
                .frame(width: 260, height: 260)
                .offset(x: -80, y: -60)
                .blur(radius: 2)
            Circle()
                .fill(RadialGradient(colors: [Color(hex: "#c8600a").opacity(0.35), .clear],
                                     center: .center, startRadius: 0, endRadius: 100))
                .frame(width: 200, height: 200)
                .offset(x: 90, y: 60)
                .blur(radius: 2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {

                    // ── Header
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alerts")
                            .font(WT.display(28, weight: .bold))
                            .foregroundStyle(WT.textPrimary)
                        Text("Thresholds & notifications")
                            .font(WT.body(11))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .padding(.bottom, 4)

                    // ── Threshold slider card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OVER-TEMP THRESHOLD")
                            .font(WT.body(10, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(WT.textMuted)

                        HStack {
                            Text("50°F")
                                .font(WT.body(13))
                                .foregroundStyle(Color.white.opacity(0.4))
                            Spacer()
                            Text(String(format: "%.0f°F", vm.thresholdF))
                                .font(WT.body(18, weight: .semibold))
                                .foregroundStyle(Color(hex: "#f5c542"))
                            Spacer()
                            Text("100°F")
                                .font(WT.body(13))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }

                        // NOTE: The actual threshold is set by the potentiometer on the ESP32.
                        // This slider shows the current value read from the firmware payload.
                        // In a production app you could POST a desired threshold to Cloud Run.
                        Slider(value: $vm.thresholdF, in: 50...100, step: 1)
                            .tint(
                                LinearGradient(
                                    colors: [Color(hex: "#b5d45a"), Color(hex: "#f5c542"), Color(hex: "#ff5e3a")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )

                        Text("Reflects potentiometer reading from ESP32")
                            .font(WT.body(10))
                            .foregroundStyle(Color.white.opacity(0.2))
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // ── Notification toggles
                    Text("NOTIFICATIONS")
                        .font(WT.body(10, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(Color.white.opacity(0.28))
                        .padding(.top, 4)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ToggleRow(
                            icon: "thermometer.high",
                            iconColor: Color(hex: "#f5c842"),
                            title: "Over-temperature",
                            subtitle: "Buzzer + push · when temp exceeds threshold",
                            isOn: $overTempOn
                        )
                        Divider().background(Color.white.opacity(0.06))
                        ToggleRow(
                            icon: "cloud.rain",
                            iconColor: Color(hex: "#93c5fd"),
                            title: "Rain prediction",
                            subtitle: "Push · pressure drops > 2 hPa / 30s",
                            isOn: $rainOn
                        )
                        Divider().background(Color.white.opacity(0.06))
                        ToggleRow(
                            icon: "humidity",
                            iconColor: Color(hex: "#93c5fd"),
                            title: "High humidity",
                            subtitle: "Push · when humidity exceeds 85%",
                            isOn: $highHumOn
                        )
                        Divider().background(Color.white.opacity(0.06))
                        ToggleRow(
                            icon: "wifi.slash",
                            iconColor: WT.accent,
                            title: "Sensor offline",
                            subtitle: "Push · no reading for > 30 seconds",
                            isOn: $offlineOn
                        )
                    }
                    .background(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // ── Alert history
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "Alert history today")
                            if vm.alertEvents.isEmpty {
                                Text("No alerts triggered yet")
                                    .font(WT.body(12))
                                    .italic()
                                    .foregroundStyle(Color.white.opacity(0.25))
                            } else {
                                ForEach(vm.alertEvents.prefix(6)) { event in
                                    AlertHistoryRow(event: event)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 110)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AlertHistoryRow
// ─────────────────────────────────────────────────────────────────────────────

struct AlertHistoryRow: View {
    let event: AlertEvent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: event.type.iconName)
                .foregroundStyle(event.type.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.type.label)
                    .font(WT.body(12, weight: .medium))
                    .foregroundStyle(WT.textPrimary)
                Text("\(String(format: "%.0f", event.tempF))°F · \(event.timestamp.formatted(date: .omitted, time: .shortened))")
                    .font(WT.body(11))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            Spacer()
        }
    }
}

#Preview {
    AlertsView(vm: WeatherViewModel())
}
