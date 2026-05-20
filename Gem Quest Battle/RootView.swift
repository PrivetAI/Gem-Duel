import SwiftUI

final class AppRouter: ObservableObject {
    @Published var activeBattle: BattleDef? = nil
    @Published var showOnboarding: Bool = false
}

struct RootView: View {
    @EnvironmentObject var store: SaveStore
    @StateObject private var router = AppRouter()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            GQBBackground()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { WorldMapView(router: router) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { HeroView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { ShopView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { BestiaryView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { SettingsView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
        }
        .fullScreenCover(item: $router.activeBattle) { battle in
            BattleView(battle: battle, router: router)
                .environmentObject(store)
        }
        .onChange(of: router.activeBattle?.globalIndex) { _ in
            // Bridge the shared store into the battle screen's StateObject init.
            BattleView.storeHolder = store
        }
        .sheet(isPresented: $router.showOnboarding) {
            OnboardingView { router.showOnboarding = false }
        }
        .onAppear {
            if !store.save.onboardingDone {
                router.showOnboarding = true
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Quest") { AnyView(MapPinShape().fill($0)) }
            tabButton(1, "Hero") { AnyView(HeroMarkShape().fill($0)) }
            tabButton(2, "Shop") { AnyView(BagGlyph().stroke($0, style: StrokeStyle(lineWidth: 2, lineJoin: .round))) }
            tabButton(3, "Bestiary") { AnyView(BookGlyph().stroke($0, lineWidth: 2)) }
            tabButton(4, "Settings") { AnyView(GearGlyph().fill($0)) }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            GQBTheme.bgDeep
                .overlay(Rectangle().fill(GQBTheme.cardStroke.opacity(0.4)).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(_ index: Int, _ label: String,
                           _ icon: @escaping (Color) -> AnyView) -> some View {
        let active = selectedTab == index
        let color = active ? GQBTheme.gold : GQBTheme.textFaint
        return Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                icon(color)
                    .frame(width: 24, height: 24)
                Text(label)
                    .font(.system(size: 10, weight: active ? .bold : .medium, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
