import SwiftUI

/// Shared visual language for FCS-Destiny: a dark, premium sports SaaS palette built on a
/// blue-violet / bordeaux tone (not the green/teal of the original EA-FC-style reference),
/// with amber reserved for premium/achievement moments and a dedicated green kept only for
/// positive stat deltas, where the +/- convention is expected regardless of brand color.
enum FDTheme {
    // MARK: Core palette (HSL values converted to RGB)
    static let bg = Color(red: 0.065, green: 0.1733, blue: 0.195)            // hsl(190 50% 13%)
    static let card = Color(red: 0.1044, green: 0.2052, blue: 0.2556)        // hsl(200 42% 18%)
    static let primary = Color(red: 0.5376, green: 0.354, blue: 0.966)       // hsl(258 90% 66%) blue-violet
    static let accentTeal = Color(red: 0.775, green: 0.225, blue: 0.3625)    // hsl(345 55% 50%) bordeaux
    static let textPrimary = Color(red: 0.9664, green: 0.9718, blue: 0.9736)
    static let textMuted = Color(red: 0.894, green: 0.899, blue: 0.906)
    static let destructive = Color(red: 0.9388, green: 0.3812, blue: 0.4184) // hsl(356 82% 66%)
    static let amber = Color(red: 0.984, green: 0.749, blue: 0.141)          // #fbbf24 — premium/crown
    static let warning = Color(red: 0.8852, green: 0.7179, blue: 0.2948)     // hsl(43 72% 59%)
    static let success = Color(red: 0.0, green: 0.94, blue: 0.47)            // hsl(150 100% 47%) — kept green for +/- deltas only

    // Ambient background glow, part of the same blue-violet/bordeaux family as primary.
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

    // MARK: Surfaces
    //
    // Cards used to be one flat fill with a hairline. These give them a little depth
    // without changing any layout: a top-lit gradient body and a border that fades from
    // a lit edge to nothing, the way a panel catches light from above.

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.055), Color.white.opacity(0.012)],
            startPoint: .top, endPoint: .bottom
        )
    }

    static var cardStroke: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.16), Color.white.opacity(0.05)],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// A tinted header band that fades out to the right instead of sitting as a flat block.
    static func headerWash(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.22), color.opacity(0.03)],
            startPoint: .leading, endPoint: .trailing
        )
    }

    /// The ambient glow behind the main screens: two offset pools of colour rather than a
    /// single radial, so the background has a direction instead of a flat vignette.
    static var ambientGlow: some View {
        ZStack {
            RadialGradient(
                colors: [violetGlow.opacity(0.30), .clear],
                center: UnitPoint(x: 0.12, y: 0.02), startRadius: 8, endRadius: 420
            )
            RadialGradient(
                colors: [accentTeal.opacity(0.22), .clear],
                center: UnitPoint(x: 0.95, y: 0.85), startRadius: 8, endRadius: 460
            )
        }
        .blur(radius: 60)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// Value-driven colour for a statistic: poor reads muted, good reads primary,
    /// excellent reads success — so a stat block has a visible shape at a glance now
    /// that the bars are gone.
    static func statColor(_ value: Int) -> Color {
        switch value {
        case 85...: return success
        case 70..<85: return primary
        case 50..<70: return accentTeal
        default: return textMuted.opacity(0.65)
        }
    }
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

    /// The standard card surface used across every screen: the base card colour, a
    /// top-lit gradient over it and a border that fades downward. Replaces the old
    /// flat fill + hairline pair, and keeps that treatment in one place.
    func fdCardSurface(corner: CGFloat = FDTheme.radiusCard) -> some View {
        self
            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .background(FDTheme.cardGradient, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(FDTheme.cardStroke, lineWidth: 1)
            )
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
            .font(.caption.weight(.bold))
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

/// Press feedback for grid/list choice items (position, nationality, club, foot…) — a spring
/// scale on tap so committing to a choice reads as a physical "pop" rather than an instant swap.
struct FDChoiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.fdSnap, value: configuration.isPressed)
    }
}

/// Subtle press feedback for full-width list/menu rows that shouldn't look like pill buttons —
/// a small scale + opacity dip so every tappable row in the app responds to touch, not just
/// the primary/secondary button styles.
struct FDRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.fdSnap, value: configuration.isPressed)
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

// MARK: - Motion

/// Shared spring curves so every hand-built animation in the app (not just ButtonStyle presses)
/// feels like it belongs to the same system.
extension Animation {
    /// Snappy feedback for taps, selections, toggles.
    static let fdSnap = Animation.spring(response: 0.32, dampingFraction: 0.68)
    /// Slightly looser spring for larger movements (sheets, step transitions, card reveals).
    static let fdSoft = Animation.spring(response: 0.45, dampingFraction: 0.8)
    /// Staggered list/grid entrance — call with an increasing `index` per item.
    static func fdStagger(_ index: Int, base: Double = 0.05) -> Animation {
        .spring(response: 0.42, dampingFraction: 0.78).delay(Double(index) * base)
    }
}

/// Directional slide+fade, used when swapping whole screens or wizard steps so navigation reads
/// as physical movement instead of a flat crossfade.
extension AnyTransition {
    static func fdSlide(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }
}

/// Any view can now `.fdAppear(delay:)` to fade/rise into place — used to stagger list rows,
/// menu items and stat cards on first appearance instead of popping in all at once.
private struct FDAppearModifier: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
            .onAppear {
                withAnimation(.fdSoft.delay(delay)) { shown = true }
            }
    }
}

extension View {
    func fdAppear(delay: Double = 0) -> some View {
        modifier(FDAppearModifier(delay: delay))
    }

    /// Adds a light scale/opacity "give" to any tappable view that isn't already a Button —
    /// keeps ad-hoc tap targets (rows, chips, icons) feeling as responsive as the button styles.
    func fdPressable(scale: CGFloat = 0.95) -> some View {
        modifier(FDPressableModifier(scale: scale))
    }

    /// A slow, looping glow pulse used to draw the eye to one element (e.g. "resume career"),
    /// never more than one per screen so it stays a signal rather than noise.
    func fdPulse() -> some View {
        modifier(FDPulseModifier())
    }
}

private struct FDPressableModifier: ViewModifier {
    let scale: CGFloat
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? scale : 1)
            .animation(.fdSnap, value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}

private struct FDPulseModifier: ViewModifier {
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: FDTheme.primary.opacity(pulsing ? 0.55 : 0.15), radius: pulsing ? 14 : 4)
            .scaleEffect(pulsing ? 1.03 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}
