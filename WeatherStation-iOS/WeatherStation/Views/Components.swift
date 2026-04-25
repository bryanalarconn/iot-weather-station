import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Design tokens (mirror the prototype's CSS variables)
// ─────────────────────────────────────────────────────────────────────────────

struct WT { // WeatherTokens
    static let accent      = Color(hex: "#b5d45a")   // green accent
    static let surface     = Color.white.opacity(0.08)
    static let border      = Color.white.opacity(0.13)
    static let textPrimary = Color.white
    static let textMuted   = Color.white.opacity(0.38)
    static let textDim     = Color.white.opacity(0.22)

    // Corner radius
    static let r: CGFloat = 22
    static let rSmall: CGFloat = 14

    // Typography
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Georgia", size: size).weight(weight) // closest to Playfair on iOS
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .monospaced)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - GlassCard
// ─────────────────────────────────────────────────────────────────────────────

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WT.r))
            .overlay(
                RoundedRectangle(cornerRadius: WT.r)
                    .stroke(WT.border, lineWidth: 1)
            )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LivePill
// ─────────────────────────────────────────────────────────────────────────────

struct LivePill: View {
    @State private var blink = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(WT.accent)
                .frame(width: 5, height: 5)
                .opacity(blink ? 0.2 : 1)
                .animation(.easeInOut(duration: 1).repeatForever(), value: blink)
            Text("LIVE")
                .font(WT.body(10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.18), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear { blink = true }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ComfortBadge
// ─────────────────────────────────────────────────────────────────────────────

struct ComfortBadge: View {
    let zone: ComfortZone

    var body: some View {
        HStack(spacing: 8) {
            Text(zone.emoji)
            Text(zone.rawValue)
                .font(WT.body(13, weight: .semibold))
        }
        .foregroundStyle(zone.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(zone.color.opacity(0.13))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(zone.color.opacity(0.28), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut(duration: 0.6), value: zone.color)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ComfortTrack  (gradient bar + thumb)
// ─────────────────────────────────────────────────────────────────────────────

struct ComfortTrack: View {
    let zone: ComfortZone
    let tempF: Double

    private var thumbPct: Double { zone.trackPercent(tempF: tempF) }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Gradient track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [Color(hex: "#4a9eff"), Color(hex: "#b5d45a"),
                                     Color(hex: "#f5c542"), Color(hex: "#ff5e3a")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(height: 6)

                    // Thumb
                    Circle()
                        .fill(.white)
                        .shadow(color: .white.opacity(0.5), radius: 6)
                        .frame(width: 16, height: 16)
                        .offset(x: geo.size.width * thumbPct / 100 - 8)
                        .animation(.spring(response: 1, dampingFraction: 0.6), value: thumbPct)
                }
            }
            .frame(height: 16)

            // Zone labels
            HStack {
                Text("❄ Cold").font(WT.body(9, weight: .semibold)).foregroundStyle(WT.textDim)
                Spacer()
                Text("✦ Good").font(WT.body(9, weight: .semibold)).foregroundStyle(WT.textDim)
                Spacer()
                Text("☀ Warm").font(WT.body(9, weight: .semibold)).foregroundStyle(WT.textDim)
                Spacer()
                Text("🔥 Hot").font(WT.body(9, weight: .semibold)).foregroundStyle(WT.textDim)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - StatCell
// ─────────────────────────────────────────────────────────────────────────────

struct StatCell: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(WT.mono(21))
                    .foregroundStyle(WT.textPrimary)
                Text(unit)
                    .font(WT.body(10, weight: .regular))
                    .foregroundStyle(WT.textPrimary)
                    .baselineOffset(8)
            }
            Text(label.uppercased())
                .font(WT.body(9, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(WT.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SectionTitle
// ─────────────────────────────────────────────────────────────────────────────

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(WT.body(10, weight: .semibold))
            .tracking(1.0)
            .foregroundStyle(WT.textMuted)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ToggleRow
// ─────────────────────────────────────────────────────────────────────────────

struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WT.body(14, weight: .semibold))
                    .foregroundStyle(WT.textPrimary)
                Text(subtitle)
                    .font(WT.body(11))
                    .foregroundStyle(WT.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(WT.accent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SettingRow
// ─────────────────────────────────────────────────────────────────────────────

struct SettingRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color.white.opacity(0.4)

    var body: some View {
        HStack {
            Text(label)
                .font(WT.body(14, weight: .medium))
                .foregroundStyle(WT.textPrimary)
            Spacer()
            Text(value)
                .font(WT.body(13))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color.white.opacity(0.07))
        .overlay(Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - RangeBar
// ─────────────────────────────────────────────────────────────────────────────

struct RangeBar: View {
    let fill: Double   // 0–1
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.1))
                RoundedRectangle(cornerRadius: 2).fill(color)
                    .frame(width: geo.size.width * fill)
                    .animation(.spring(response: 0.8), value: fill)
            }
        }
        .frame(height: 4)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SkyBackground
// ─────────────────────────────────────────────────────────────────────────────

struct SkyBackground: View {
    let zone: ComfortZone
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: zone.skyColors,
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Floating orbs (mimic the CSS .orb animation)
            Circle()
                .fill(RadialGradient(
                    colors: [zone.color.opacity(0.45), .clear],
                    center: .center, startRadius: 0, endRadius: 150
                ))
                .frame(width: 300, height: 300)
                .offset(x: -60 + phase * 10, y: -80 + phase * 15)
                .blur(radius: 2)

            Circle()
                .fill(RadialGradient(
                    colors: [zone.color.opacity(0.25), .clear],
                    center: .center, startRadius: 0, endRadius: 120
                ))
                .frame(width: 240, height: 240)
                .offset(x: 80 + phase * -8, y: 60 + phase * 12)
                .blur(radius: 2)

            // Bottom fade-to-dark
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.55), Color.black.opacity(0.88)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: phase)
        .onAppear { phase = 1 }
    }
}
