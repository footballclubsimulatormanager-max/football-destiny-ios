import SwiftUI
import UIKit

@main
struct FootballDestinyApp: App {
    init() {
        FDAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            FDRootView()
                .preferredColorScheme(.dark)
        }
    }
}

/// One-time UIKit appearance configuration so native chrome (navigation bars, tab bar,
/// any remaining table/list) matches the app's branded look everywhere, not just the
/// screens built with custom SwiftUI components.
enum FDAppearance {
    static func configure() {
        let titleFont = UIFont(name: "BarlowSemiCondensed-BlackItalic", size: 18) ?? UIFont.boldSystemFont(ofSize: 18)

        let navBar = UINavigationBarAppearance()
        navBar.configureWithOpaqueBackground()
        navBar.backgroundColor = UIColor(FDTheme.bg)
        navBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: titleFont]
        navBar.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar
        UINavigationBar.appearance().compactAppearance = navBar
        UINavigationBar.appearance().tintColor = UIColor(FDTheme.primary)

        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = UIColor(FDTheme.bg)
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
        UITabBar.appearance().tintColor = UIColor(FDTheme.primary)

        UITableView.appearance().backgroundColor = UIColor(FDTheme.bg)
        UITableViewCell.appearance().backgroundColor = .clear
    }
}
