import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: SaveStore
    @State private var showPrivacy = false
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            GQBBackground()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        prefsCard
                        aboutCard
                        dataCard
                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPrivacy) {
            GemDuelWebPanel(urlString: "https://gemduel.org/click.php")
                .edgesIgnoringSafeArea(.all)
        }
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(GQBTheme.text)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var prefsCard: some View {
        PanelCard {
            VStack(spacing: 14) {
                SectionHeader(title: "Preferences")
                toggleRow(title: "Sound", isOn: Binding(
                    get: { store.save.soundOn },
                    set: { store.save.soundOn = $0 }))
                Divider().background(GQBTheme.cardStroke.opacity(0.4))
                toggleRow(title: "Haptics", isOn: Binding(
                    get: { store.save.hapticsOn },
                    set: { store.save.hapticsOn = $0 }))
            }
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(GQBTheme.text)
            Spacer()
            // Custom toggle (no system styling reliance for theme independence).
            Button(action: { isOn.wrappedValue.toggle() }) {
                ZStack(alignment: isOn.wrappedValue ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn.wrappedValue ? GQBTheme.gold : GQBTheme.panelHi)
                        .frame(width: 50, height: 28)
                    Circle()
                        .fill(GQBTheme.text)
                        .frame(width: 22, height: 22)
                        .padding(.horizontal, 3)
                }
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: isOn.wrappedValue)
        }
    }

    private var aboutCard: some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: "About")
                Button(action: { showPrivacy = true }) {
                    HStack {
                        BookGlyph().stroke(GQBTheme.gold, lineWidth: 2).frame(width: 18, height: 18)
                        Text("Privacy Policy")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(GQBTheme.text)
                        Spacer()
                        ChevronLeftShape()
                            .stroke(GQBTheme.textFaint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 8, height: 12)
                            .rotationEffect(.degrees(180))
                    }
                }
                .buttonStyle(.plain)
                HStack {
                    Text("Version")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(GQBTheme.textDim)
                    Spacer()
                    Text("1.0")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(GQBTheme.text)
                }
            }
        }
    }

    private var dataCard: some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Data")
                if showResetConfirm {
                    Text("Reset all progress? This cannot be undone.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(GQBTheme.textDim)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 10) {
                        Button("Cancel") { showResetConfirm = false }
                            .buttonStyle(OutlineButtonStyle())
                        Button(action: {
                            store.resetAll()
                            showResetConfirm = false
                        }) {
                            Text("Reset")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(GQBTheme.danger))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button("Reset Progress") { showResetConfirm = true }
                        .buttonStyle(OutlineButtonStyle())
                }
            }
        }
    }
}
