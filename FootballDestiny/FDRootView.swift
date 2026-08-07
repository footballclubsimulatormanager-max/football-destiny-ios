import SwiftUI

enum FDScreen: Hashable {
    case menu, creation, game
}

/// Top-level view of the app: menu → career creation → game shell.
struct FDRootView: View {
    @StateObject private var engine = FDGameEngine()
    @State private var screen: FDScreen = .menu

    var body: some View {
        Group {
            switch screen {
            case .menu:
                FDMainMenuView(engine: engine, screen: $screen)
            case .creation:
                FDCareerCreationView(engine: engine, screen: $screen)
            case .game:
                FDGameShellView(engine: engine, screen: $screen)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: screen)
    }
}
