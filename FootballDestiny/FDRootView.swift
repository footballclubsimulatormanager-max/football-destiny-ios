import SwiftUI

enum FDScreen: Hashable {
    case menu, creation, game
}

/// Top-level view of the app: menu → career creation → game shell.
struct FDRootView: View {
    @StateObject private var engine = FDGameEngine()
    @State private var screen: FDScreen = .menu

    /// Screens are ordered menu → creation → game; moving to a "later" screen slides in from
    /// the right, moving back slides in from the left, so navigation reads as physical depth.
    private func isForward(from old: FDScreen, to new: FDScreen) -> Bool {
        func rank(_ s: FDScreen) -> Int {
            switch s {
            case .menu: return 0
            case .creation: return 1
            case .game: return 2
            }
        }
        return rank(new) >= rank(old)
    }

    var body: some View {
        Group {
            switch screen {
            case .menu:
                FDMainMenuView(engine: engine, screen: $screen)
                    .transition(.fdSlide(forward: isForward(from: previousScreen, to: .menu)))
            case .creation:
                FDCareerCreationView(engine: engine, screen: $screen)
                    .transition(.fdSlide(forward: isForward(from: previousScreen, to: .creation)))
            case .game:
                FDGameShellView(engine: engine, screen: $screen)
                    .transition(.fdSlide(forward: isForward(from: previousScreen, to: .game)))
            }
        }
        .animation(.fdSoft, value: screen)
        .onChange(of: screen) { new in
            previousScreen = new
        }
    }

    @State private var previousScreen: FDScreen = .menu
}
