import SwiftUI

/// Shared visual language for FCS-Destiny: palette, gradients, card and button styles.
enum FDTheme {
    static let gold = Color(red: 0.83, green: 0.68, blue: 0.21)
    static let goldLight = Color(red: 0.96, green: 0.84, blue: 0.52)
    static let ink = Color(red: 0.07, green: 0.05, blue: 0.14)
    static let inkElevated = Color(red: 0.18, green: 0.10, blue: 0.32)
    static let violetGlow = Color(red: 0.58, green: 0.26, blue: 0.86)

    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [ink, inkElevated], startPoint: .top, endPoint: .bottom)
    }

    static var goldTextGradient: LinearGradient {
        LinearGradient(colors: [goldLight, gold], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Card

struct FDCardBackground: ViewModifier {
    var padding: CGFloat = 16
    var corner: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 16, y: 8)
    }
}

extension View {
    func fdCard(padding: CGFloat = 16, corner: CGFloat = 20) -> some View {
        modifier(FDCardBackground(padding: padding, corner: corner))
    }
}

// MARK: - Fields

struct FDFieldBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func fdField() -> some View { modifier(FDFieldBackground()) }
}

/// Small uppercase caption used to head a card's content, in place of a Form section header.
struct FDSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(Color.accentColor)
    }
}

/// A symbol (emoji or SF Symbol) contained in a tinted rounded badge, used everywhere an
/// icon appears next to a title so it reads as a designed element rather than a loose glyph.
struct FDIconBadge: View {
    let symbol: String
    var tint: Color = FDTheme.gold
    var size: CGFloat = 44
    var isSystemImage: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(tint.opacity(0.16))
            if isSystemImage {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tint)
            } else {
                Text(symbol)
                    .font(.system(size: size * 0.46))
            }
        }
        .frame(width: size, height: size)
    }
}

extension Font {
    /// The app's branded title/label voice: rounded design, used everywhere instead of the
    /// plain system font so headings and card titles read as one consistent typeface family.
    static func fdRounded(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

// MARK: - Buttons

/// Gold gradient pill, used for the one primary action on a screen.
struct FDPrimaryButtonStyle: ButtonStyle {
    var tint: Color = FDTheme.gold

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(FDTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [
                        tint.opacity(configuration.isPressed ? 0.75 : 1.0),
                        tint.opacity(configuration.isPressed ? 0.55 : 0.75)
                    ],
                    startPoint: .top, endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(
                color: tint.opacity(configuration.isPressed ? 0.15 : 0.35),
                radius: configuration.isPressed ? 6 : 14,
                y: configuration.isPressed ? 2 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Neutral card-colored button, used for secondary actions on light/adaptive backgrounds.
struct FDSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Translucent outline button, used for secondary actions over the dark hero background.
struct FDSecondaryDarkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Plain text link, used for tertiary/low-emphasis actions.
struct FDGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
