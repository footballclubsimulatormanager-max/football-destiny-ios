import SwiftUI
import Foundation

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

    /// The narrative voice. The reference the app follows sets its stories in the same
    /// sans as the rest of the interface — a serif read as foreign here — so the story
    /// stays in Barlow and earns its weight from size and line spacing instead.
    static func story(_ size: CGFloat, bold: Bool = false, italic: Bool = false) -> Font {
        .custom(bold ? "Barlow-Black" : "Barlow-Regular", size: size)
    }

    /// Headlines — scene titles and chronicle mastheads — in the app's own slanted
    /// display face, the one already used for names and titles.
    static func headline(_ size: CGFloat, italic: Bool = true) -> Font {
        .custom(italic ? "BarlowSemiCondensed-BlackItalic" : "BarlowSemiCondensed-Black", size: size)
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
            .font(.subheadline.weight(.bold))
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
            .font(FDFont.body(19, black: true))
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
            .font(FDFont.body(19, black: true))
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
            .font(FDFont.body(19, black: true))
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
            .font(FDFont.body(18, black: true))
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

// MARK: - L'illustration d'une scène

/// Ce qu'on dessine derrière une scène. Le narratif portait tout seul depuis le début ;
/// une image par scène lui donne son décor sans coûter un seul fichier d'illustration —
/// tout est tracé à la volée, dans le style d'un panneau de manga de football : contrastes
/// durs, silhouettes noires, trames de points et lignes de vitesse.
enum FDArtKind {
    case terrain, vestiaire, stade, dispute, presse, argent, famille
    case infirmerie, voyage, trophee, entrainement, solitude, nuit
}

/// À quelle image correspond chaque catégorie de scène.
func fdSceneArtKind(_ category: String) -> FDArtKind {
    switch category {
    case "Entraînement", "Préparation", "Poste", "Identité de jeu": return .entrainement
    case "Vestiaire", "Staff", "Jeunes": return .vestiaire
    case "Match important", "Moment décisif", "Coupe", "Europe", "Derby", "Calendrier": return .stade
    case "Presse", "Réseaux", "Sponsor": return .presse
    case "Crise", "Rivalité", "Coach", "Arbitrage", "Leadership": return .dispute
    case "Argent", "Contrat", "Agent", "Transfert": return .argent
    case "Famille", "Couple", "Amis", "Logement", "Ville": return .famille
    case "Blessure": return .infirmerie
    case "Voyage", "Sélection": return .voyage
    case "Trophée", "Star", "Héritage": return .trophee
    case "Mental", "Retraite", "Vétéran": return .solitude
    case "Hygiène de vie", "Superstition": return .nuit
    case "Supporters", "Club": return .stade
    default: return .terrain
    }
}

/// Le panneau dessiné au-dessus du texte d'une scène. Tout est tracé : aucune image n'est
/// embarquée, la carte reste légère et chaque catégorie a son décor.
struct FDSceneArt: View {
    let category: String
    let tint: Color
    let seedText: String

    private var seed: Int {
        var total = 0
        for scalar in seedText.unicodeScalars { total = (total &* 31 &+ Int(scalar.value)) % 100_003 }
        return total
    }

    var body: some View {
        let kind = fdSceneArtKind(category)
        let seed = self.seed
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let ink = Color(red: 0.02, green: 0.05, blue: 0.07)

            // Le fond : d'abord une nuit franche, ensuite seulement la couleur de la
            // catégorie qui l'effleure. Poser la teinte sans base opaque délavait tout le
            // panneau et lui donnait un ton kaki.
            let night = Color(red: 0.03, green: 0.07, blue: 0.09)
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(night))
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: [tint.opacity(0.27), .clear]),
                                           startPoint: CGPoint(x: w * 0.15, y: 0),
                                           endPoint: CGPoint(x: w * 0.9, y: h)))

            // La trame de points, en bas à gauche, comme une trame de manga.
            for row in 0..<7 {
                for col in 0..<26 {
                    let x = CGFloat(col) * (w / 26) + 3
                    let y = h - CGFloat(row) * 9 - 5
                    let fade = 1.0 - Double(row) / 7.0 - Double(col) / 34.0
                    guard fade > 0.05 else { continue }
                    let r = 1.0 + fade * 1.6
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(.white.opacity(fade * 0.10)))
                }
            }

            // Les lignes de vitesse, en éventail depuis le coin haut droit.
            for i in 0..<16 {
                let spread = CGFloat(i) * (h / 7) - h
                var line = Path()
                line.move(to: CGPoint(x: w + 10, y: spread))
                line.addLine(to: CGPoint(x: w * 0.34, y: spread + h * 0.9))
                ctx.stroke(line, with: .color(.white.opacity(i % 3 == 0 ? 0.10 : 0.045)),
                           lineWidth: i % 4 == 0 ? 2.2 : 1)
            }

            FDSceneArt.draw(kind, in: &ctx, w: w, h: h, tint: tint, ink: ink, seed: seed)

            // Le trait d'action : une diagonale franche qui traverse le panneau.
            var slash = Path()
            slash.move(to: CGPoint(x: -4, y: h * 0.34))
            slash.addLine(to: CGPoint(x: w * 0.22, y: -6))
            ctx.stroke(slash, with: .color(tint.opacity(0.7)), lineWidth: 3)
        }
        .frame(height: 104)
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    // MARK: Les décors

    /// Une silhouette humaine, tête et buste, suffisante à cette taille.
    private static func figure(_ ctx: inout GraphicsContext, x: CGFloat, ground: CGFloat,
                               height: CGFloat, color: Color, flip: Bool = false) {
        let headR = height * 0.17
        let headY = ground - height + headR
        ctx.fill(Path(ellipseIn: CGRect(x: x - headR, y: headY - headR, width: headR * 2, height: headR * 2)),
                 with: .color(color))
        var torso = Path()
        let shoulder = headY + headR * 1.4
        let halfTop = height * 0.20, halfBottom = height * 0.13
        let tilt: CGFloat = flip ? -height * 0.05 : height * 0.05
        torso.move(to: CGPoint(x: x - halfTop + tilt, y: shoulder))
        torso.addLine(to: CGPoint(x: x + halfTop + tilt, y: shoulder))
        torso.addLine(to: CGPoint(x: x + halfBottom, y: ground))
        torso.addLine(to: CGPoint(x: x - halfBottom, y: ground))
        torso.closeSubpath()
        ctx.fill(torso, with: .color(color))
    }

    private static func draw(_ kind: FDArtKind, in ctx: inout GraphicsContext,
                             w: CGFloat, h: CGFloat, tint: Color, ink: Color, seed: Int) {
        let dark = ink.opacity(0.92)
        let ground = h * 0.86

        switch kind {
        case .terrain, .entrainement:
            // La pelouse en fuite, le rond central, et un ballon posé.
            var grass = Path()
            grass.move(to: CGPoint(x: 0, y: ground))
            grass.addLine(to: CGPoint(x: w, y: ground - h * 0.10))
            grass.addLine(to: CGPoint(x: w, y: h))
            grass.addLine(to: CGPoint(x: 0, y: h))
            grass.closeSubpath()
            ctx.fill(grass, with: .color(tint.opacity(0.16)))
            for i in 0..<5 {
                var line = Path()
                let y = ground + CGFloat(i) * 4
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: w, y: y - h * 0.10))
                ctx.stroke(line, with: .color(.white.opacity(0.07)), lineWidth: 1)
            }
            ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.30, y: ground - 8, width: w * 0.40, height: 22)),
                       with: .color(.white.opacity(0.22)), lineWidth: 1.5)
            let ballR: CGFloat = 6
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.72, y: ground - ballR, width: ballR * 2, height: ballR * 2)),
                     with: .color(.white.opacity(0.85)))
            if kind == .entrainement {
                for i in 0..<4 {
                    let x = w * 0.12 + CGFloat(i) * w * 0.13
                    var cone = Path()
                    cone.move(to: CGPoint(x: x, y: ground - 12))
                    cone.addLine(to: CGPoint(x: x + 6, y: ground))
                    cone.addLine(to: CGPoint(x: x - 6, y: ground))
                    cone.closeSubpath()
                    ctx.fill(cone, with: .color(tint.opacity(0.75)))
                }
                figure(&ctx, x: w * 0.80, ground: ground, height: h * 0.62, color: dark)
            } else {
                figure(&ctx, x: w * 0.84, ground: ground, height: h * 0.66, color: dark)
            }

        case .stade:
            // Les tribunes, deux tours d'éclairage, et la foule en points.
            var stand = Path()
            stand.move(to: CGPoint(x: 0, y: h * 0.62))
            stand.addLine(to: CGPoint(x: w * 0.5, y: h * 0.40))
            stand.addLine(to: CGPoint(x: w, y: h * 0.62))
            stand.addLine(to: CGPoint(x: w, y: ground))
            stand.addLine(to: CGPoint(x: 0, y: ground))
            stand.closeSubpath()
            ctx.fill(stand, with: .color(dark))
            for row in 0..<4 {
                for col in 0..<30 {
                    let x = CGFloat(col) * (w / 30) + 4
                    let y = h * 0.50 + CGFloat(row) * 7 + abs(x - w / 2) * 0.06
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2.6, height: 2.6)),
                             with: .color(tint.opacity(0.55 - Double(row) * 0.1)))
                }
            }
            for side in [CGFloat(0.13), CGFloat(0.87)] {
                var beam = Path()
                beam.move(to: CGPoint(x: w * side, y: 4))
                beam.addLine(to: CGPoint(x: w * side - 26, y: ground))
                beam.addLine(to: CGPoint(x: w * side + 26, y: ground))
                beam.closeSubpath()
                ctx.fill(beam, with: .color(.white.opacity(0.07)))
                ctx.fill(Path(ellipseIn: CGRect(x: w * side - 5, y: 2, width: 10, height: 8)),
                         with: .color(.white.opacity(0.75)))
            }
            ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)),
                     with: .color(tint.opacity(0.18)))

        case .vestiaire:
            // Le mur de casiers et un maillot sur son cintre.
            for i in 0..<7 {
                let x = CGFloat(i) * (w / 7)
                ctx.fill(Path(CGRect(x: x + 3, y: h * 0.16, width: w / 7 - 6, height: h * 0.58)),
                         with: .color(i % 2 == 0 ? dark : ink.opacity(0.75)))
                ctx.stroke(Path(CGRect(x: x + 3, y: h * 0.16, width: w / 7 - 6, height: h * 0.58)),
                           with: .color(tint.opacity(0.35)), lineWidth: 1)
                ctx.fill(Path(ellipseIn: CGRect(x: x + w / 7 - 12, y: h * 0.44, width: 4, height: 4)),
                         with: .color(.white.opacity(0.5)))
            }
            ctx.fill(Path(CGRect(x: 0, y: h * 0.74, width: w, height: 7)), with: .color(tint.opacity(0.55)))
            var shirt = Path()
            let cx = w * 0.5
            shirt.move(to: CGPoint(x: cx - 16, y: h * 0.24))
            shirt.addLine(to: CGPoint(x: cx + 16, y: h * 0.24))
            shirt.addLine(to: CGPoint(x: cx + 12, y: h * 0.62))
            shirt.addLine(to: CGPoint(x: cx - 12, y: h * 0.62))
            shirt.closeSubpath()
            ctx.fill(shirt, with: .color(.white.opacity(0.88)))

        case .dispute:
            // Deux silhouettes face à face et l'éclair entre elles.
            figure(&ctx, x: w * 0.26, ground: ground, height: h * 0.74, color: dark)
            figure(&ctx, x: w * 0.74, ground: ground, height: h * 0.74, color: dark, flip: true)
            var bolt = Path()
            bolt.move(to: CGPoint(x: w * 0.50, y: h * 0.16))
            bolt.addLine(to: CGPoint(x: w * 0.455, y: h * 0.48))
            bolt.addLine(to: CGPoint(x: w * 0.515, y: h * 0.46))
            bolt.addLine(to: CGPoint(x: w * 0.47, y: h * 0.80))
            bolt.addLine(to: CGPoint(x: w * 0.56, y: h * 0.42))
            bolt.addLine(to: CGPoint(x: w * 0.505, y: h * 0.44))
            bolt.addLine(to: CGPoint(x: w * 0.545, y: h * 0.16))
            bolt.closeSubpath()
            ctx.fill(bolt, with: .color(tint))
            ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(dark))

        case .presse:
            // La forêt de micros et les flashs.
            for i in 0..<6 {
                let x = w * 0.16 + CGFloat(i) * w * 0.13
                let top = h * (0.30 + Double(i % 3) * 0.07)
                var stick = Path()
                stick.move(to: CGPoint(x: x, y: h))
                stick.addLine(to: CGPoint(x: x + 4, y: top + 10))
                ctx.stroke(stick, with: .color(dark), lineWidth: 3)
                ctx.fill(Path(roundedRect: CGRect(x: x - 5, y: top, width: 12, height: 16), cornerRadius: 5),
                         with: .color(i % 2 == 0 ? tint : Color.white.opacity(0.8)))
            }
            for i in 0..<3 {
                let x = w * (0.2 + Double(i) * 0.3), y = h * 0.2
                var star = Path()
                star.move(to: CGPoint(x: x, y: y - 9))
                star.addLine(to: CGPoint(x: x + 3, y: y - 3))
                star.addLine(to: CGPoint(x: x + 9, y: y))
                star.addLine(to: CGPoint(x: x + 3, y: y + 3))
                star.addLine(to: CGPoint(x: x, y: y + 9))
                star.addLine(to: CGPoint(x: x - 3, y: y + 3))
                star.addLine(to: CGPoint(x: x - 9, y: y))
                star.addLine(to: CGPoint(x: x - 3, y: y - 3))
                star.closeSubpath()
                ctx.fill(star, with: .color(.white.opacity(0.85)))
            }

        case .argent:
            // Une pile de jetons et un billet, sous une lumière froide.
            for i in 0..<5 {
                let y = ground - CGFloat(i) * 7
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.62 - 26, y: y - 9, width: 52, height: 14)),
                         with: .color(i % 2 == 0 ? tint : tint.opacity(0.65)))
            }
            var bill = Path(roundedRect: CGRect(x: w * 0.14, y: h * 0.40, width: w * 0.30, height: h * 0.26),
                            cornerRadius: 4)
            ctx.fill(bill, with: .color(.white.opacity(0.85)))
            bill = Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.47, width: 14, height: 14))
            ctx.fill(bill, with: .color(ink))
            figure(&ctx, x: w * 0.88, ground: ground, height: h * 0.6, color: dark)

        case .famille:
            // Un toit, une fenêtre allumée, deux silhouettes devant.
            var roof = Path()
            roof.move(to: CGPoint(x: w * 0.10, y: h * 0.52))
            roof.addLine(to: CGPoint(x: w * 0.42, y: h * 0.22))
            roof.addLine(to: CGPoint(x: w * 0.74, y: h * 0.52))
            roof.closeSubpath()
            ctx.fill(roof, with: .color(dark))
            ctx.fill(Path(CGRect(x: w * 0.16, y: h * 0.52, width: w * 0.52, height: ground - h * 0.52)),
                     with: .color(dark))
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.34, y: h * 0.58, width: 26, height: 20), cornerRadius: 3),
                     with: .color(tint.opacity(0.85)))
            figure(&ctx, x: w * 0.80, ground: ground, height: h * 0.52, color: dark)
            figure(&ctx, x: w * 0.90, ground: ground, height: h * 0.36, color: dark)
            ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(dark))

        case .infirmerie:
            // La table de soins, la jambe bandée, la croix.
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.12, y: h * 0.56, width: w * 0.62, height: 12),
                          cornerRadius: 4), with: .color(.white.opacity(0.8)))
            for x in [w * 0.18, w * 0.66] {
                ctx.fill(Path(CGRect(x: x, y: h * 0.68, width: 5, height: ground - h * 0.68)),
                         with: .color(dark))
            }
            var leg = Path()
            leg.move(to: CGPoint(x: w * 0.20, y: h * 0.52))
            leg.addLine(to: CGPoint(x: w * 0.52, y: h * 0.44))
            ctx.stroke(leg, with: .color(dark), lineWidth: 13)
            ctx.stroke(leg, with: .color(.white.opacity(0.85)), lineWidth: 5)
            let cx = w * 0.86, cy = h * 0.30
            ctx.fill(Path(CGRect(x: cx - 4, y: cy - 13, width: 8, height: 26)), with: .color(tint))
            ctx.fill(Path(CGRect(x: cx - 13, y: cy - 4, width: 26, height: 8)), with: .color(tint))

        case .voyage:
            // L'avion, l'horizon et la piste.
            var plane = Path()
            plane.move(to: CGPoint(x: w * 0.18, y: h * 0.42))
            plane.addLine(to: CGPoint(x: w * 0.66, y: h * 0.30))
            plane.addLine(to: CGPoint(x: w * 0.70, y: h * 0.36))
            plane.addLine(to: CGPoint(x: w * 0.40, y: h * 0.46))
            plane.closeSubpath()
            ctx.fill(plane, with: .color(.white.opacity(0.9)))
            var wing = Path()
            wing.move(to: CGPoint(x: w * 0.42, y: h * 0.36))
            wing.addLine(to: CGPoint(x: w * 0.50, y: h * 0.14))
            wing.addLine(to: CGPoint(x: w * 0.56, y: h * 0.34))
            wing.closeSubpath()
            ctx.fill(wing, with: .color(tint))
            var horizon = Path()
            horizon.move(to: CGPoint(x: 0, y: ground))
            horizon.addLine(to: CGPoint(x: w, y: ground - 6))
            ctx.stroke(horizon, with: .color(.white.opacity(0.35)), lineWidth: 2)
            ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(dark))

        case .trophee:
            // La coupe, les rayons, l'estrade.
            for i in 0..<9 {
                var ray = Path()
                ray.move(to: CGPoint(x: w * 0.5, y: h * 0.46))
                let angle = Double(i) * .pi / 9 + .pi
                ray.addLine(to: CGPoint(x: w * 0.5 + CGFloat(cos(angle)) * w,
                                        y: h * 0.46 + CGFloat(sin(angle)) * h))
                ctx.stroke(ray, with: .color(tint.opacity(i % 2 == 0 ? 0.22 : 0.10)), lineWidth: 6)
            }
            var cup = Path()
            cup.move(to: CGPoint(x: w * 0.44, y: h * 0.22))
            cup.addLine(to: CGPoint(x: w * 0.56, y: h * 0.22))
            cup.addLine(to: CGPoint(x: w * 0.53, y: h * 0.56))
            cup.addLine(to: CGPoint(x: w * 0.47, y: h * 0.56))
            cup.closeSubpath()
            ctx.fill(cup, with: .color(tint))
            ctx.fill(Path(CGRect(x: w * 0.455, y: h * 0.56, width: w * 0.09, height: 8)), with: .color(tint))
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.40, y: h * 0.64, width: w * 0.20, height: 9),
                          cornerRadius: 2), with: .color(.white.opacity(0.85)))
            ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(dark))

        case .solitude:
            // Une seule silhouette, assise, et beaucoup de vide autour.
            ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(dark))
            ctx.fill(Path(CGRect(x: w * 0.58, y: h * 0.62, width: w * 0.34, height: 8)),
                     with: .color(dark))
            figure(&ctx, x: w * 0.72, ground: h * 0.62, height: h * 0.42, color: dark)
            var horizonLine = Path()
            horizonLine.move(to: CGPoint(x: 0, y: ground))
            horizonLine.addLine(to: CGPoint(x: w, y: ground))
            ctx.stroke(horizonLine, with: .color(tint.opacity(0.5)), lineWidth: 2)

        case .nuit:
            // La ville la nuit : des fenêtres allumées, et une silhouette qui rentre.
            for i in 0..<6 {
                let bw = w / 6.5
                let bh = h * (0.30 + Double((seed / (i + 1)) % 5) * 0.09)
                let x = CGFloat(i) * (w / 6) + 3
                ctx.fill(Path(CGRect(x: x, y: ground - bh, width: bw, height: bh)), with: .color(dark))
                for row in 0..<3 {
                    for col in 0..<2 {
                        guard (seed / (row + i + col + 1)) % 3 != 0 else { continue }
                        ctx.fill(Path(CGRect(x: x + 5 + CGFloat(col) * 11,
                                             y: ground - bh + 7 + CGFloat(row) * 11,
                                             width: 6, height: 6)),
                                 with: .color(tint.opacity(0.8)))
                    }
                }
            }
            ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(ink))
            figure(&ctx, x: w * 0.5, ground: h, height: h * 0.5, color: ink.opacity(0.98))
        }
    }
}
