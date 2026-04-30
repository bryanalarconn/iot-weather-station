import SwiftUI
import Charts

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HistoryView  (Screen 2: History)
// ─────────────────────────────────────────────────────────────────────────────

struct HistoryView: View {
    @ObservedObject var vm: WeatherViewModel

    var body: some View {
        ZStack {
            // Background matching prototype's hist-screen gradient
            LinearGradient(
                colors: [Color(hex: "#0d1a0a"), Color(hex: "#1a2d10"), Color(hex: "#0f1f0a")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating orbs
            Circle()
                .fill(RadialGradient(colors: [Color(hex: "#2d5a10").opacity(0.5), .clear],
                                     center: .center, startRadius: 0, endRadius: 130))
                .frame(width: 260, height: 260)
                .offset(x: 80, y: -60)
                .blur(radius: 2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {

                    // ── Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("History")
                                .font(WT.display(28, weight: .bold))
                                .foregroundStyle(WT.textPrimary)
                            Text("Last \(vm.history.count) readings · 30 seconds")
                                .font(WT.body(11))
                                .foregroundStyle(Color.white.opacity(0.3))
                        }
                        Spacer()
                        LivePill()
                    }
                    .padding(.bottom, 4)

                    // ── Temperature chart
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "Temperature over time (°F)")

                            if vm.tempHistory.isEmpty {
                                Text("Waiting for data…")
                                    .font(WT.body(12))
                                    .foregroundStyle(WT.textMuted)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 130)
                            } else {
                                TempChart(history: vm.history)
                                    .frame(height: 130)

                                // X-axis labels
                                HStack {
                                    ForEach(chartLabelIndices, id: \.self) { i in
                                        if i < vm.history.count {
                                            Text("-\((vm.history.count - 1 - i) * 3)s")
                                                .font(WT.body(9, weight: .semibold))
                                                .foregroundStyle(Color.white.opacity(0.25))
                                            if i != chartLabelIndices.last { Spacer() }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── 24h High / Low
                    HStack(spacing: 10) {
                        HistStatCard(
                            label: "24h High",
                            value: vm.high24h > 0 ? "\(Int(vm.high24h))°F" : "--",
                            sub: "Max observed",
                            fill: vm.high24h > 0 ? (vm.high24h - 50) / 60 : 0,
                            barColor: Color(hex: "#ff5e3a")
                        )
                        HistStatCard(
                            label: "24h Low",
                            value: vm.low24h > 0 ? "\(Int(vm.low24h))°F" : "--",
                            sub: "Min observed",
                            fill: vm.low24h > 0 ? (vm.low24h - 50) / 60 : 0,
                            barColor: Color(hex: "#4a9eff")
                        )
                    }

                    // ── Avg Humidity / Pressure trend
                    HStack(spacing: 10) {
                        HistStatCard(
                            label: "Avg Humidity",
                            value: vm.history.isEmpty ? "--" : "\(Int(vm.avgHum))%",
                            sub: "Last \(vm.history.count) readings",
                            fill: vm.avgHum / 100,
                            barColor: Color(hex: "#60a5fa")
                        )
                        HistStatCard(
                            label: "Pressure Trend",
                            value: vm.pressureTrend,
                            sub: vm.pressureTrend == "Falling" ? "Rain predicted" : "No rain predicted",
                            fill: vm.pressureTrend == "Falling" ? 0.3 : 0.55,
                            barColor: vm.pressureTrend == "Falling" ? Color(hex: "#60a5fa") : WT.accent
                        )
                    }

                    // ── Rain events
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "Rain events today")
                            let rainReadings = vm.history.filter(\.rain_likely)
                            if rainReadings.isEmpty {
                                Text("No rain events today")
                                    .font(WT.body(12))
                                    .italic()
                                    .foregroundStyle(Color.white.opacity(0.25))
                            } else {
                                FlowLayout(spacing: 6) {
                                    ForEach(rainReadings.suffix(6)) { r in
                                        Text(r.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(WT.body(11, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#93c5fd"))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color(hex: "#60a5fa").opacity(0.15))
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: "#60a5fa").opacity(0.3), lineWidth: 1))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
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

    private var chartLabelIndices: [Int] {
        guard !vm.history.isEmpty else { return [] }
        let count = vm.history.count
        return stride(from: 0, to: count, by: max(1, count / 4)).map { $0 } + [count - 1]
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - TempChart  (Swift Charts)
// ─────────────────────────────────────────────────────────────────────────────

struct TempChart: View {
    let history: [WeatherReading]

    struct DataPoint: Identifiable {
        let id: Int
        let tempF: Double
    }

    var points: [DataPoint] {
        history.enumerated().map { DataPoint(id: $0.offset, tempF: $0.element.temp_f) }
    }

    var body: some View {
        Chart {
            ForEach(points) { pt in
                AreaMark(
                    x: .value("Index", pt.id),
                    y: .value("°F", pt.tempF)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#b5d45a").opacity(0.3), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Index", pt.id),
                    y: .value("°F", pt.tempF)
                )
                .foregroundStyle(Color(hex: "#b5d45a"))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Index", pt.id),
                    y: .value("°F", pt.tempF)
                )
                .foregroundStyle(Color(hex: "#b5d45a"))
                .symbolSize(20)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.25))
                    .font(WT.body(9))
            }
        }
        .chartPlotStyle { area in
            area.background(.clear)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HistStatCard
// ─────────────────────────────────────────────────────────────────────────────

struct HistStatCard: View {
    let label: String
    let value: String
    let sub: String
    let fill: Double
    let barColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(WT.body(9, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(0.35))
            Text(value)
                .font(WT.mono(22))
                .foregroundStyle(WT.textPrimary)
            Text(sub)
                .font(WT.body(10))
                .foregroundStyle(Color.white.opacity(0.3))
            RangeBar(fill: max(0, min(1, fill)), color: barColor)
                .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FlowLayout (for rain event pills)
// ─────────────────────────────────────────────────────────────────────────────

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for view in subviews {
            let s = view.sizeThatFits(.unspecified)
            if x + s.width > width, x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for view in subviews {
            let s = view.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}

#Preview {
    HistoryView(vm: WeatherViewModel())
}
