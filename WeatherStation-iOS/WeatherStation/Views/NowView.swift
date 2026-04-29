import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NowView  (Screen 1: Dashboard)
// Mirrors the prototype's Dashboard screen exactly.
// ─────────────────────────────────────────────────────────────────────────────

struct NowView: View {
    @ObservedObject var vm: WeatherViewModel

    @State private var zenQuote  = ""
    @State private var condWord  = "Comfortable"
    @State private var condSub   = "Outside"

    var reading: WeatherReading { vm.current ?? WeatherViewModel.simulated() }
    var zone: ComfortZone { vm.zone }

    private func refreshWords() {
        let words: [ComfortZone: [String]] = [
            .cold: ["Crisp", "Chilly"],
            .good: ["Comfortable", "Pleasant"],
            .warm: ["Warm", "Sunny"],
            .hot:  ["Hot", "Scorching"],
            .rain: ["Cloudy", "Rainy"]
        ]
        let subs: [ComfortZone: String] = [
            .cold: "& Still",
            .good: "Outside",
            .warm: "& Bright",
            .hot:  "& Dry",
            .rain: "& Grey"
        ]
        condWord = words[zone]?.randomElement() ?? zone.rawValue
        condSub  = subs[zone] ?? "Outside"
        zenQuote = zone.zenQuotes.randomElement() ?? ""
    }

    var body: some View {
        ZStack {
            SkyBackground(zone: zone)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Station label
                    Text("ESP32 · Backyard")
                        .font(WT.body(11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.top, 4)

                    // ── Condition headline
                    VStack(alignment: .leading, spacing: 0) {
                        Text(condWord)
                            .font(WT.display(42, weight: .bold))
                            .foregroundStyle(WT.textPrimary)
                        Text(condSub)
                            .font(Font.custom("Georgia-Italic", size: 42))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .padding(.top, 4)

                    // ── Temperature row
                    HStack(alignment: .bottom, spacing: 12) {
                        HStack(alignment: .top, spacing: 1) {
                            Text(String(Int(reading.temp_f)))
                                .font(WT.mono(88))
                                .foregroundStyle(WT.textPrimary)
                            Text("°F")
                                .font(WT.body(32, weight: .light))
                                .foregroundStyle(WT.textPrimary)
                                .padding(.top, 10)
                        }
                        Text(String(format: "%.1f °C", reading.temp_c))
                            .font(WT.body(16, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .padding(.bottom, 14)
                    }

                    // ── Comfort badge + track
                    ComfortBadge(zone: zone)
                        .padding(.bottom, 10)

                    ComfortTrack(zone: zone, tempF: reading.temp_f)
                        .padding(.bottom, 14)

                    // ── Sensors card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Sensors")
                            HStack {
                                StatCell(value: String(Int(reading.humidity)), unit: "%",   label: "Humidity")
                                StatCell(value: String(Int(reading.pressure_hpa)), unit: "hPa", label: "Pressure")
                                StatCell(value: String(Int(reading.light_pct)), unit: "%",   label: "Light")
                            }
                        }
                    }

                    // ── Rain + Buzzer row
                    HStack(spacing: 10) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 4) {
                                SectionTitle(text: "Rain")
                                Text(reading.rain_likely ? "Rain likely" : "Clear")
                                    .font(WT.body(18, weight: .semibold))
                                    .foregroundStyle(reading.rain_likely ? Color(hex: "#60a5fa") : WT.accent)
                                Text(reading.rain_likely ? "Pressure dropping" : "Pressure stable")
                                    .font(WT.body(10))
                                    .foregroundStyle(WT.textMuted)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 4) {
                                SectionTitle(text: "Buzzer")
                                Text("Threshold")
                                    .font(WT.body(10))
                                    .foregroundStyle(WT.textMuted)
                                Text(String(format: "%.0f°F", vm.thresholdF))
                                    .font(WT.body(18, weight: .semibold))
                                    .foregroundStyle(WT.textPrimary)
                                AlertChip(exceeded: reading.temp_f > vm.thresholdF)
                            }
                        }
                    }
                    .padding(.top, 10)

                    // ── Heat index row
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                SectionTitle(text: "Feels like")
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text(String(format: "%.1f", reading.heat_index_f))
                                        .font(WT.mono(28))
                                        .foregroundStyle(WT.textPrimary)
                                    Text("°F")
                                        .font(WT.body(14))
                                        .foregroundStyle(WT.textMuted)
                                }
                                Text("Heat index (NOAA formula)")
                                    .font(WT.body(10))
                                    .foregroundStyle(WT.textMuted)
                            }
                            Spacer()
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 32, weight: .ultraLight))
                                .foregroundStyle(zone.color.opacity(0.7))
                        }
                    }
                    .padding(.top, 10)

                    // ── Zen quote
                    Text("\u{201C}\(zenQuote)\u{201D}")
                        .font(Font.custom("Georgia-Italic", size: 12))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    // ── Timestamp
                    if let ts = vm.lastUpdated {
                        Text("Updated \(ts.formatted(date: .omitted, time: .standard))")
                            .font(WT.body(10))
                            .foregroundStyle(Color.white.opacity(0.18))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 110) // nav bar clearance
            }
        }
        .onAppear {
            refreshWords()
        }
        .onChange(of: vm.current?.temp_f) {
            refreshWords()
        }
    }

    // condWord / condSub are now @State, set via refreshWords() above
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AlertChip
// ─────────────────────────────────────────────────────────────────────────────

struct AlertChip: View {
    let exceeded: Bool
    @State private var pulse = false

    var body: some View {
        Text(exceeded ? "ALERT" : "STANDBY")
            .font(WT.body(10, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(exceeded ? Color(hex: "#ff8060") : Color.white.opacity(0.45))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(exceeded ? Color(hex: "#ff5e3a").opacity(0.2) : Color.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(exceeded ? Color(hex: "#ff5e3a").opacity(0.4) : Color.white.opacity(0.13),
                            lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .opacity(exceeded ? (pulse ? 0.45 : 1.0) : 1.0)
            .animation(exceeded
                       ? .easeInOut(duration: 0.6).repeatForever()
                       : .default,
                       value: pulse)
            .onAppear { if exceeded { pulse = true } }
            .onChange(of: exceeded) { pulse = exceeded }
    }
}

#Preview {
    NowView(vm: {
        let vm = WeatherViewModel()
        vm.current = WeatherViewModel.simulated()
        return vm
    }())
}
