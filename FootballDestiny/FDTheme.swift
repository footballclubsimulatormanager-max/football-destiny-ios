import SwiftUI

/// Shared visual language for FCS-Destiny: a dark, EA-FC-style sports SaaS palette
/// (navy background, neon-green primary, amber for premium/achievement moments),
/// with one deliberate deviation from the reference: the ambient background glow
/// is blue-violet instead of green/teal.
enum FDTheme {
    // MARK: Core palette (HSL values converted to RGB)
    static let bg = Color(red: 0.065, green: 0.1733, blue: 0.195)            // hsl(190 50% 13%)
    static let card = Color(red: 0.1044, green: 0.2052, blue: 0.2556)        // hsl(200 42% 18%)
    static let primary = Color(red: 0.0, green: 0.94, blue: 0.47)            // hsl(150 100% 47%) neon green
    static let accentTeal = Color(red: 0.09, green: 0.81, blue: 0.81)        // hsl(180 80% 45%)
    static let textPrimary = Color(red: 0.9664, green: 0.9718, blue: 0.9736)
    static let textMuted = Color(red: 0.894, green: 0.899, blue: 0.906)
    static let destructive = Color(red: 0.9388, green: 0.3812, blue: 0.4184) // hsl(356 82% 66%)
    static let amber = Color(red: 0.984, green: 0.749, blue: 0.141)          // #fbbf24 — premium/crown
    static let warning = Color(red: 0.8852, green: 0.7179, blue: 0.2948)     // hsl(43 72% 59%)
    static let success = primary

    // Deliberate exception to the reference: ambient glow is blue-violet, not green/teal.
    static let violetGlow = Color(red: 0.46, green: 0.28, blue: 0.95)
    static let blueGlow = Color(red: 0.20, green: 0.35, blue: 0.95)

    // Back-compat aliases (older call sites still read these names).
    static let gold = amber
    static let goldLight = Color(red: 0.996, green: 0.851, blue: 0.4)
    static let ink = bg
    static let inkElevated = card

    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [bg, card], startPoint: .top, endPoint: .bottom)
    }

    static var goldTextGradient: LinearGradient {
        LinearGradient(colors: [goldLight, amber], startPoint: .leading, endPoint: .trailing)
    }

    static var primaryTextGradient: LinearGradient {
        LinearGradient(colors: [accentTeal, primary], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: Shape scale ("arrondi modéré" — 10px base, 9/6/3 tiers, 12–16px cards)
    static let radiusSM: CGFloat = 3
    static let radiusMD: CGFloat = 6
    static let radiusLG: CGFloat = 9
    static let radiusCard: CGFloat = 16
}

// MARK: - Fonts
// Barlow (body) / Barlow Semi Condensed Black Italic (display, "penché façon jersey") /
// JetBrains Mono (stat figures). Falls back to the system font automatically if a font
// name doesn't resolve, so a bundling hiccup degrades gracefully instead of crashing.
enum FDFont {
    static func display(_ size: CGFloat, italic: Bool = true) -> Font {
        .custom(italic ? "BarlowSemiCondensed-BlackItalic" : "BarlowSemiCondensed-Black", size: size)
    }

    static func body(_ size: CGFloat, black: Bool = false) -> Font {
        .custom(black ? "Barlow-Black" : "Barlow-Regular", size: size)
    }

    static func mono(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "JetBrainsMono-Bold" : "JetBrainsMono-Regular", size: size)
    }
}

extension Font {
    /// The app's branded title/label voice: rounded design, used for secondary text
    /// (chips, small labels) that doesn't warrant the full display treatment.
    static func fdRounded(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

// MARK: - Card

struct FDCardBackground: ViewModifier {
    var padding: CGFloat = 16
    var corner: CGFloat = FDTheme.radiusCard

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(FDTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
    }
}

extension View {
    func fdCard(padding: CGFloat = 16, corner: CGFloat = FDTheme.radiusCard) -> some View {
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
                RoundedRectangle(cornerRadius: FDTheme.radiusLG, style: .continuous)
                    .fill(FDTheme.bg.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FDTheme.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
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
            .foregroundStyle(FDTheme.accentTeal)
    }
}

/// A symbol (emoji or SF Symbol) contained in a tinted rounded badge, used everywhere an
/// icon appears next to a title so it reads as a designed element rather than a loose glyph.
struct FDIconBadge: View {
    let symbol: String
    var tint: Color = FDTheme.primary
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

/// The FCS-Destiny logo mark, sized to fit wherever a small brand badge is needed.
struct FDLogoBadge: View {
    var size: CGFloat = 34
    var corner: CGFloat = 10

    var body: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Buttons

/// Neon-green gradient pill, used for the one primary action on a screen.
struct FDPrimaryButtonStyle: ButtonStyle {
    var tint: Color = FDTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FDFont.body(17, black: true))
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
                in: RoundedRectangle(cornerRadius: FDTheme.radiusCard, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FDTheme.radiusCard, style: .continuous)
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

/// Neutral card-colored button, used for secondary actions.
struct FDSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FDFont.body(17, black: true))
            .foregroundStyle(FDTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: FDTheme.radiusCard, style: .continuous)
                    .fill(FDTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FDTheme.radiusCard, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
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
            .font(FDFont.body(17, black: true))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: FDTheme.radiusCard, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FDTheme.radiusCard, style: .continuous)
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

/// Red-pink outline button, used for destructive actions (retire, reset a career).
struct FDDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FDFont.body(16, black: true))
            .foregroundStyle(FDTheme.destructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: FDTheme.radiusCard, style: .continuous)
                    .fill(FDTheme.destructive.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FDTheme.radiusCard, style: .continuous)
                    .stroke(FDTheme.destructive.opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
