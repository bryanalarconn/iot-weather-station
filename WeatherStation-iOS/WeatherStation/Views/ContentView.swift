import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ContentView  (App shell with custom glass nav bar)
// ─────────────────────────────────────────────────────────────────────────────

struct ContentView: View {
    @StateObject private var vm = WeatherViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Tab content (paged, no default tab bar)
            Group {
                switch selectedTab {
                case 0: NowView(vm: vm)
                case 1: HistoryView(vm: vm)
                case 2: AlertsView(vm: vm)
                case 3: SettingsView(vm: vm)
                default: NowView(vm: vm)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)

            // ── Custom glass nav bar (matches prototype exactly)
            WeatherNavBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        // ── Load preview data in simulator / preview
        .onAppear {
            #if DEBUG
            // Seed with simulated data so the UI looks alive immediately.
            // Remove this block once your Cloud Run endpoint is live.
            let seed = WeatherViewModel.simulated()
            vm.applyReading(seed)
            // Keep seeding every 3s to simulate live sensor data
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                Task { @MainActor in
                    vm.applyReading(WeatherViewModel.simulated())
                }
            }
            #endif
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - WeatherNavBar
// ─────────────────────────────────────────────────────────────────────────────

struct WeatherNavBar: View {
    @Binding var selectedTab: Int

    private let items: [(icon: String, label: String)] = [
        ("sun.max",       "Now"),
        ("chart.line.uptrend.xyaxis", "History"),
        ("bell",          "Alerts"),
        ("slider.horizontal.3", "Settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                NavBarButton(
                    icon: items[i].icon,
                    label: items[i].label,
                    isActive: selectedTab == i
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 28)   // home indicator clearance
        .padding(.top, 8)
        .frame(height: 86)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color.white.opacity(0.09)), alignment: .top)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NavBarButton
// ─────────────────────────────────────────────────────────────────────────────

struct NavBarButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? Color.white.opacity(0.12) : Color.clear)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(
                            isActive
                            ? Color(hex: "#e8f0c8")
                            : Color(hex: "#e8f0c8").opacity(0.38)
                        )
                }

                Text(label.uppercased())
                    .font(WT.body(9, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(isActive
                                     ? Color.white.opacity(0.85)
                                     : Color.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isActive ? Color.white.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isActive ? Color.white.opacity(0.14) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────────────────

#Preview {
    ContentView()
}
