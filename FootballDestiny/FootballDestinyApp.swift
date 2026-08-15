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
        // A hair lighter than the page so the bar itself reads as a distinct strip, plus a
        // top hairline: on a near-black background an untinted bar simply disappears.
        tabBar.backgroundColor = UIColor(FDTheme.card)
        tabBar.shadowColor = UIColor.white.withAlphaComponent(0.14)

        // Unselected items default to a mid grey that is nearly invisible on this palette,
        // so both states are set explicitly, with a readable label size.
        let selected = UIColor(FDTheme.primary)
        let unselected = UIColor.white.withAlphaComponent(0.62)
        for item in [tabBar.stackedLayoutAppearance, tabBar.inlineLayoutAppearance, tabBar.compactInlineLayoutAppearance] {
            item.normal.iconColor = unselected
            item.normal.titleTextAttributes = [
                .foregroundColor: unselected,
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
            item.selected.iconColor = selected
            item.selected.titleTextAttributes = [
                .foregroundColor: selected,
                .font: UIFont.systemFont(ofSize: 11, weight: .bold)
            ]
        }

        UITabBar.appearance().standardAppearance = tabBar
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBar
        }
        UITabBar.appearance().tintColor = selected
        UITabBar.appearance().unselectedItemTintColor = unselected
        UITabBar.appearance().isTranslucent = false

        // The career sub-tabs use a segmented control; the system one is grey-on-grey here.
        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = UIColor(FDTheme.primary)
        seg.backgroundColor = UIColor(FDTheme.bg)
        seg.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.7),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ], for: .normal)
        seg.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 12, weight: .bold)
        ], for: .selected)

        UITableView.appearance().backgroundColor = UIColor(FDTheme.bg)
        UITableViewCell.appearance().backgroundColor = .clear
    }
}
