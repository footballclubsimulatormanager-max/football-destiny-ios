import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

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

    /// Le nom de l'illustration attendue dans le catalogue d'images pour ce décor. Si elle
    /// existe, elle remplace le dessin ; sinon le panneau tracé prend le relais. On peut donc
    /// ajouter les images une par une, sans jamais casser l'écran.
    static func assetName(_ kind: FDArtKind) -> String {
        switch kind {
        case .terrain: return "ArtTerrain"
        case .vestiaire: return "ArtVestiaire"
        case .stade: return "ArtStade"
        case .dispute: return "ArtDispute"
        case .presse: return "ArtPresse"
        case .argent: return "ArtArgent"
        case .famille: return "ArtFamille"
        case .infirmerie: return "ArtInfirmerie"
        case .voyage: return "ArtVoyage"
        case .trophee: return "ArtTrophee"
        case .entrainement: return "ArtEntrainement"
        case .solitude: return "ArtSolitude"
        case .nuit: return "ArtNuit"
        }
    }

    var body: some View {
        let kind = fdSceneArtKind(category)
        // Une vraie illustration si elle a été fournie pour ce décor, sinon le panneau tracé :
        // nuit, halo de lumière, trame d'imprimé et silhouettes articulées.
        if UIImage(named: FDSceneArt.assetName(kind)) != nil {
            illustration(kind)
        } else {
            drawn(kind)
        }
    }

    /// L'image fournie, recadrée dans la bande et fondue vers le bas pour que le texte de la
    /// scène s'y accroche au lieu d'être posé contre une arête franche.
    private func illustration(_ kind: FDArtKind) -> some View {
        Image(FDSceneArt.assetName(kind))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, FDTheme.bg.opacity(0.85)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 46)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
            }
    }

    private func drawn(_ kind: FDArtKind) -> some View {
        Canvas { ctx, size in
            FDSceneArt.paint(kind, in: &ctx, size: size, tint: FDSceneArt.atmosphere(kind, tint: tint))
        }
        .frame(height: 120)
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    // MARK: Le vocabulaire graphique

    /// La couleur d'ambiance d'un décor. Les teintes d'interface sont trop saturées pour
    /// remplir un panneau entier : elles éclairent une pastille, elles ne peignent pas une
    /// nuit. Chaque décor a donc sa version sourde.
    static func atmosphere(_ kind: FDArtKind, tint: Color) -> Color {
        switch kind {
        case .terrain, .entrainement: return Color(red: 0.247, green: 0.639, blue: 0.478)
        case .stade, .trophee: return Color(red: 0.878, green: 0.659, blue: 0.235)
        case .vestiaire, .voyage: return Color(red: 0.482, green: 0.388, blue: 0.839)
        case .dispute: return Color(red: 0.851, green: 0.322, blue: 0.372)
        case .presse: return Color(red: 0.502, green: 0.596, blue: 0.780)
        case .argent: return Color(red: 0.847, green: 0.729, blue: 0.404)
        case .famille: return Color(red: 0.918, green: 0.639, blue: 0.376)
        case .infirmerie: return Color(red: 0.404, green: 0.694, blue: 0.780)
        case .solitude, .nuit: return Color(red: 0.408, green: 0.502, blue: 0.647)
        }
    }

    private static let ink = Color(red: 0.012, green: 0.031, blue: 0.043)

    /// Les poses, en coordonnées normalisées dans une boîte 0…1 (y vers le bas). Une
    /// silhouette faite de segments épais à bouts ronds lit comme un corps ; un trapèze,
    /// non — c'était le défaut de la première version.
    private static func pose(_ name: String) -> (head: CGPoint, neck: CGPoint, hip: CGPoint, limbs: [[CGPoint]]) {
        switch name {
        case "course":
            return (CGPoint(x: 0.55, y: 0.09), CGPoint(x: 0.51, y: 0.20), CGPoint(x: 0.42, y: 0.52), [
                [CGPoint(x: 0.51, y: 0.22), CGPoint(x: 0.68, y: 0.30), CGPoint(x: 0.74, y: 0.44)],
                [CGPoint(x: 0.51, y: 0.22), CGPoint(x: 0.33, y: 0.30), CGPoint(x: 0.22, y: 0.22)],
                [CGPoint(x: 0.42, y: 0.52), CGPoint(x: 0.62, y: 0.68), CGPoint(x: 0.70, y: 0.86)],
                [CGPoint(x: 0.42, y: 0.52), CGPoint(x: 0.28, y: 0.70), CGPoint(x: 0.12, y: 0.66)]])
        case "frappe":
            return (CGPoint(x: 0.46, y: 0.09), CGPoint(x: 0.47, y: 0.20), CGPoint(x: 0.45, y: 0.52), [
                [CGPoint(x: 0.47, y: 0.22), CGPoint(x: 0.28, y: 0.26), CGPoint(x: 0.16, y: 0.36)],
                [CGPoint(x: 0.47, y: 0.22), CGPoint(x: 0.64, y: 0.30), CGPoint(x: 0.72, y: 0.22)],
                [CGPoint(x: 0.45, y: 0.52), CGPoint(x: 0.66, y: 0.60), CGPoint(x: 0.86, y: 0.52)],
                [CGPoint(x: 0.45, y: 0.52), CGPoint(x: 0.40, y: 0.72), CGPoint(x: 0.36, y: 0.92)]])
        case "brasCroises":
            return (CGPoint(x: 0.50, y: 0.09), CGPoint(x: 0.50, y: 0.20), CGPoint(x: 0.50, y: 0.54), [
                [CGPoint(x: 0.50, y: 0.24), CGPoint(x: 0.30, y: 0.34), CGPoint(x: 0.58, y: 0.40)],
                [CGPoint(x: 0.50, y: 0.24), CGPoint(x: 0.70, y: 0.34), CGPoint(x: 0.42, y: 0.40)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.44, y: 0.74), CGPoint(x: 0.43, y: 0.95)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.58, y: 0.74), CGPoint(x: 0.59, y: 0.95)]])
        case "assis":
            return (CGPoint(x: 0.44, y: 0.30), CGPoint(x: 0.47, y: 0.40), CGPoint(x: 0.52, y: 0.66), [
                [CGPoint(x: 0.47, y: 0.42), CGPoint(x: 0.40, y: 0.56), CGPoint(x: 0.46, y: 0.66)],
                [CGPoint(x: 0.47, y: 0.42), CGPoint(x: 0.56, y: 0.56), CGPoint(x: 0.50, y: 0.66)],
                [CGPoint(x: 0.52, y: 0.66), CGPoint(x: 0.30, y: 0.72), CGPoint(x: 0.28, y: 0.94)],
                [CGPoint(x: 0.52, y: 0.66), CGPoint(x: 0.34, y: 0.76), CGPoint(x: 0.32, y: 0.94)]])
        case "brasLeves":
            return (CGPoint(x: 0.50, y: 0.14), CGPoint(x: 0.50, y: 0.25), CGPoint(x: 0.50, y: 0.56), [
                [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.34, y: 0.18), CGPoint(x: 0.38, y: 0.02)],
                [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.66, y: 0.18), CGPoint(x: 0.62, y: 0.02)],
                [CGPoint(x: 0.50, y: 0.56), CGPoint(x: 0.44, y: 0.76), CGPoint(x: 0.43, y: 0.95)],
                [CGPoint(x: 0.50, y: 0.56), CGPoint(x: 0.58, y: 0.76), CGPoint(x: 0.59, y: 0.95)]])
        case "marche":
            return (CGPoint(x: 0.50, y: 0.09), CGPoint(x: 0.50, y: 0.20), CGPoint(x: 0.48, y: 0.54), [
                [CGPoint(x: 0.50, y: 0.22), CGPoint(x: 0.38, y: 0.36), CGPoint(x: 0.36, y: 0.52)],
                [CGPoint(x: 0.50, y: 0.22), CGPoint(x: 0.62, y: 0.36), CGPoint(x: 0.64, y: 0.50)],
                [CGPoint(x: 0.48, y: 0.54), CGPoint(x: 0.38, y: 0.74), CGPoint(x: 0.32, y: 0.94)],
                [CGPoint(x: 0.48, y: 0.54), CGPoint(x: 0.60, y: 0.72), CGPoint(x: 0.66, y: 0.94)]])
        default:
            return (CGPoint(x: 0.50, y: 0.09), CGPoint(x: 0.50, y: 0.20), CGPoint(x: 0.50, y: 0.54), [
                [CGPoint(x: 0.50, y: 0.22), CGPoint(x: 0.36, y: 0.38), CGPoint(x: 0.34, y: 0.54)],
                [CGPoint(x: 0.50, y: 0.22), CGPoint(x: 0.64, y: 0.38), CGPoint(x: 0.66, y: 0.54)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.44, y: 0.74), CGPoint(x: 0.43, y: 0.95)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.58, y: 0.74), CGPoint(x: 0.59, y: 0.95)]])
        }
    }

    private static func figure(_ ctx: inout GraphicsContext, x: CGFloat, ground: CGFloat,
                               height: CGFloat, _ name: String, flip: Bool = false) {
        let p = pose(name)
        func at(_ q: CGPoint) -> CGPoint {
            let fx = flip ? 1 - q.x : q.x
            return CGPoint(x: x + (fx - 0.5) * height * 0.62, y: ground - height + q.y * height)
        }
        let limbWidth = height * 0.058
        for chain in p.limbs {
            var path = Path()
            path.move(to: at(chain[0]))
            for q in chain.dropFirst() { path.addLine(to: at(q)) }
            ctx.stroke(path, with: .color(ink),
                       style: StrokeStyle(lineWidth: limbWidth, lineCap: .round, lineJoin: .round))
        }
        var torso = Path()
        torso.move(to: at(p.neck))
        torso.addLine(to: at(p.hip))
        ctx.stroke(torso, with: .color(ink),
                   style: StrokeStyle(lineWidth: height * 0.135, lineCap: .round))
        let head = at(p.head), r = height * 0.066
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - r, y: head.y - r, width: r * 2, height: r * 2)),
                 with: .color(ink))
    }

    /// La trame de points, plus dense à gauche : c'est elle qui donne le grain d'imprimé.
    private static func screentone(_ ctx: inout GraphicsContext, rect: CGRect, strength: Double) {
        var row = 0
        var y = rect.minY
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 0 : 3.5)
            while x < rect.maxX {
                let f = 1 - (x - rect.minX) / max(1, rect.width)
                if f > 0.05 {
                    let r = 1.1 + f * 1.3
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(.white.opacity(strength * f)))
                }
                x += 7
            }
            y += 7
            row += 1
        }
    }

    /// Les rayons en éventail, pour les moments qui frappent.
    private static func rays(_ ctx: inout GraphicsContext, center: CGPoint, count: Int,
                             color: Color, strength: Double) {
        for i in 0..<count {
            let angle = Double(i) * 2 * .pi / Double(count) + 0.2
            var ray = Path()
            ray.move(to: center)
            ray.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle)) * 700,
                                    y: center.y + CGFloat(sin(angle)) * 700))
            ctx.stroke(ray, with: .color(color.opacity(i % 2 == 0 ? strength : strength * 0.45)),
                       lineWidth: i % 3 == 0 ? 4 : 9)
        }
    }

    private static func ground(_ ctx: inout GraphicsContext, y: CGFloat, w: CGFloat, h: CGFloat,
                               color: Color, slant: CGFloat = 0) {
        var plane = Path()
        plane.move(to: CGPoint(x: -10, y: y))
        plane.addLine(to: CGPoint(x: w + 10, y: y - slant))
        plane.addLine(to: CGPoint(x: w + 10, y: h))
        plane.addLine(to: CGPoint(x: -10, y: h))
        plane.closeSubpath()
        ctx.fill(plane, with: .color(color))
    }

    // MARK: Les décors

    private static func paint(_ kind: FDArtKind, in ctx: inout GraphicsContext,
                              size: CGSize, tint: Color) {
        let w = size.width, h = size.height
        let night = Color(red: 0.031, green: 0.075, blue: 0.106)

        // Le ciel : la teinte n'effleure que le haut, le reste tombe dans la nuit.
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(stops: [
                    .init(color: tint.opacity(0.09), location: 0),
                    .init(color: night, location: 0.62),
                    .init(color: Color(red: 0.02, green: 0.047, blue: 0.067), location: 1)]),
                                       startPoint: CGPoint(x: 0, y: 0),
                                       endPoint: CGPoint(x: 0, y: h)))

        func glow(_ cx: CGFloat, _ cy: CGFloat, _ radius: CGFloat, _ strength: Double = 0.34) {
            ctx.fill(Path(ellipseIn: CGRect(x: cx - radius, y: cy - radius * 0.8,
                                            width: radius * 2, height: radius * 1.6)),
                     with: .radialGradient(Gradient(stops: [
                        .init(color: tint.opacity(strength), location: 0),
                        .init(color: tint.opacity(strength * 0.26), location: 0.45),
                        .init(color: .clear, location: 1)]),
                                           center: CGPoint(x: cx, y: cy),
                                           startRadius: 0, endRadius: radius))
        }

        switch kind {
        case .stade:
            glow(w * 0.30, h * 0.55, w * 0.62)
            for (yy, opacity, dots) in [(0.28, 0.55, true), (0.40, 0.8, true), (0.54, 1.0, false)] {
                var stand = Path()
                stand.move(to: CGPoint(x: -10, y: h * CGFloat(yy) + 22))
                stand.addLine(to: CGPoint(x: w * 0.5, y: h * CGFloat(yy)))
                stand.addLine(to: CGPoint(x: w + 10, y: h * CGFloat(yy) + 22))
                stand.addLine(to: CGPoint(x: w + 10, y: h * 0.9))
                stand.addLine(to: CGPoint(x: -10, y: h * 0.9))
                stand.closeSubpath()
                ctx.fill(stand, with: .color(ink.opacity(opacity)))
                if dots {
                    for c in 0..<40 {
                        let x = 4 + CGFloat(c) * (w / 40)
                        for r in 0..<2 {
                            ctx.fill(Path(ellipseIn: CGRect(x: x, y: h * CGFloat(yy) + 9 + CGFloat(r) * 8
                                                            + abs(x - w / 2) * 0.05, width: 3, height: 3)),
                                     with: .color(tint.opacity(0.30)))
                        }
                    }
                }
            }
            for sx in [CGFloat(0.08), CGFloat(0.92)] {
                var beam = Path()
                beam.move(to: CGPoint(x: w * sx, y: 0))
                beam.addLine(to: CGPoint(x: w * sx - 46, y: h * 0.9))
                beam.addLine(to: CGPoint(x: w * sx + 46, y: h * 0.9))
                beam.closeSubpath()
                ctx.fill(beam, with: .color(.white.opacity(0.05)))
                ctx.fill(Path(roundedRect: CGRect(x: w * sx - 10, y: 0, width: 20, height: 8), cornerRadius: 2),
                         with: .color(.white.opacity(0.85)))
            }
            ground(&ctx, y: h * 0.74, w: w, h: h, color: Color(red: 0.067, green: 0.161, blue: 0.122), slant: h * 0.04)
            figure(&ctx, x: w * 0.30, ground: h * 0.97, height: h * 0.66, "brasLeves")
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.45, width: w * 0.26, height: h * 0.29), strength: 0.12)

        case .terrain, .entrainement:
            glow(w * 0.70, h * 0.20, w * 0.55, 0.28)
            ground(&ctx, y: h * 0.60, w: w, h: h, color: Color(red: 0.027, green: 0.086, blue: 0.059), slant: h * 0.08)
            for i in 0..<6 {
                var stripe = Path()
                stripe.move(to: CGPoint(x: -10, y: h * 0.62 + CGFloat(i) * 11))
                stripe.addLine(to: CGPoint(x: w + 10, y: h * 0.62 + CGFloat(i) * 11 - 9))
                ctx.stroke(stripe, with: .color(.white.opacity(0.035)), lineWidth: 7)
            }
            ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.04, y: h * 0.74, width: w * 0.6, height: 34)),
                       with: .color(.white.opacity(0.16)), lineWidth: 2)
            if kind == .entrainement {
                for i in 0..<4 {
                    let x = w * 0.10 + CGFloat(i) * w * 0.11
                    var cone = Path()
                    cone.move(to: CGPoint(x: x, y: h * 0.80))
                    cone.addLine(to: CGPoint(x: x + 7, y: h * 0.90))
                    cone.addLine(to: CGPoint(x: x - 7, y: h * 0.90))
                    cone.closeSubpath()
                    ctx.fill(cone, with: .color(tint.opacity(0.8)))
                }
                figure(&ctx, x: w * 0.74, ground: h * 0.93, height: h * 0.72, "frappe")
            } else {
                figure(&ctx, x: w * 0.70, ground: h * 0.93, height: h * 0.76, "course")
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.26 - 7, y: h * 0.88 - 7, width: 13, height: 13)),
                         with: .color(Color(red: 0.929, green: 0.953, blue: 0.961)))
                for i in 0..<3 {
                    var trail = Path()
                    trail.move(to: CGPoint(x: w * 0.26 - 16 - CGFloat(i) * 11, y: h * 0.88 - CGFloat(i) * 2))
                    trail.addLine(to: CGPoint(x: w * 0.26 - 7 - CGFloat(i) * 11, y: h * 0.88 - CGFloat(i) * 2))
                    ctx.stroke(trail, with: .color(.white.opacity(0.35 - Double(i) * 0.1)), lineWidth: 2)
                }
            }
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.12, width: w * 0.34, height: h * 0.48), strength: 0.10)

        case .vestiaire:
            glow(w * 0.52, h * 0.18, w * 0.5, 0.26)
            for i in 0..<6 {
                let x = -6 + CGFloat(i) * (w / 5.5)
                let wd = w / 6.9
                ctx.fill(Path(CGRect(x: x, y: h * 0.04, width: wd, height: h * 0.68)),
                         with: .color(ink.opacity(0.88)))
                var edge = Path()
                edge.move(to: CGPoint(x: x + wd, y: h * 0.04))
                edge.addLine(to: CGPoint(x: x + wd, y: h * 0.72))
                ctx.stroke(edge, with: .color(tint.opacity(0.22)), lineWidth: 2)
                ctx.fill(Path(ellipseIn: CGRect(x: x + wd - 12, y: h * 0.38 - 2, width: 4.4, height: 4.4)),
                         with: .color(tint.opacity(0.7)))
                if i == 0 || i == 4 {
                    let cx = x + wd / 2
                    var shirt = Path()
                    shirt.move(to: CGPoint(x: cx - 18, y: h * 0.13))
                    shirt.addLine(to: CGPoint(x: cx + 18, y: h * 0.13))
                    shirt.addLine(to: CGPoint(x: cx + 13, y: h * 0.52))
                    shirt.addLine(to: CGPoint(x: cx - 13, y: h * 0.52))
                    shirt.closeSubpath()
                    ctx.fill(shirt, with: .color(Color(red: 0.863, green: 0.902, blue: 0.918).opacity(0.9)))
                    var sleeves = Path()
                    sleeves.move(to: CGPoint(x: cx - 18, y: h * 0.13))
                    sleeves.addLine(to: CGPoint(x: cx - 25, y: h * 0.22))
                    sleeves.move(to: CGPoint(x: cx + 18, y: h * 0.13))
                    sleeves.addLine(to: CGPoint(x: cx + 25, y: h * 0.22))
                    ctx.stroke(sleeves, with: .color(Color(red: 0.863, green: 0.902, blue: 0.918).opacity(0.9)),
                               style: StrokeStyle(lineWidth: 6, lineCap: .round))
                }
            }
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.10, y: h * 0.74, width: w * 0.80, height: 9), cornerRadius: 2),
                     with: .color(Color(red: 0.09, green: 0.204, blue: 0.235)))
            ctx.fill(Path(CGRect(x: w * 0.16, y: h * 0.83, width: 8, height: h * 0.17)), with: .color(ink))
            ctx.fill(Path(CGRect(x: w * 0.80, y: h * 0.83, width: 8, height: h * 0.17)), with: .color(ink))
            for bx in [w * 0.30, w * 0.44] {
                var boot = Path()
                boot.move(to: CGPoint(x: bx, y: h * 0.83))
                boot.addLine(to: CGPoint(x: bx + 6, y: h * 0.75))
                boot.addLine(to: CGPoint(x: bx + 12, y: h * 0.83))
                boot.closeSubpath()
                ctx.fill(boot, with: .color(ink))
            }
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.06, width: w * 0.26, height: h * 0.9), strength: 0.11)

        case .dispute:
            glow(w * 0.5, h * 0.42, w * 0.5)
            rays(&ctx, center: CGPoint(x: w * 0.5, y: h * 0.44), count: 30, color: .white, strength: 0.05)
            ground(&ctx, y: h * 0.90, w: w, h: h, color: ink)
            figure(&ctx, x: w * 0.36, ground: h * 0.92, height: h * 0.88, "brasCroises")
            figure(&ctx, x: w * 0.64, ground: h * 0.92, height: h * 0.88, "debout", flip: true)
            var bolt = Path()
            bolt.move(to: CGPoint(x: w * 0.502, y: h * 0.02))
            bolt.addLine(to: CGPoint(x: w * 0.482, y: h * 0.36))
            bolt.addLine(to: CGPoint(x: w * 0.516, y: h * 0.34))
            bolt.addLine(to: CGPoint(x: w * 0.492, y: h * 0.62))
            bolt.addLine(to: CGPoint(x: w * 0.534, y: h * 0.32))
            bolt.addLine(to: CGPoint(x: w * 0.504, y: h * 0.34))
            bolt.addLine(to: CGPoint(x: w * 0.526, y: h * 0.02))
            bolt.closeSubpath()
            ctx.fill(bolt, with: .color(tint.opacity(0.95)))
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.08, width: w * 0.22, height: h * 0.9), strength: 0.10)

        case .trophee:
            rays(&ctx, center: CGPoint(x: w * 0.5, y: h * 0.16), count: 26, color: tint, strength: 0.06)
            glow(w * 0.5, h * 0.16, w * 0.6, 0.30)
            ground(&ctx, y: h * 0.90, w: w, h: h, color: ink)
            figure(&ctx, x: w * 0.5, ground: h * 0.99, height: h * 0.66, "brasLeves")
            let cx = w * 0.5
            var cup = Path()
            cup.move(to: CGPoint(x: cx - 13, y: h * 0.02))
            cup.addLine(to: CGPoint(x: cx + 13, y: h * 0.02))
            cup.addLine(to: CGPoint(x: cx + 9, y: h * 0.14))
            cup.addLine(to: CGPoint(x: cx - 9, y: h * 0.14))
            cup.closeSubpath()
            let gold = Color(red: 1, green: 0.831, blue: 0.431)
            ctx.fill(cup, with: .color(gold))
            var handles = Path()
            handles.move(to: CGPoint(x: cx - 13, y: h * 0.04))
            handles.addLine(to: CGPoint(x: cx - 21, y: h * 0.10))
            handles.move(to: CGPoint(x: cx + 13, y: h * 0.04))
            handles.addLine(to: CGPoint(x: cx + 21, y: h * 0.10))
            ctx.stroke(handles, with: .color(gold), lineWidth: 3)
            ctx.fill(Path(CGRect(x: cx - 3.5, y: h * 0.14, width: 7, height: 6)), with: .color(gold))
            ctx.fill(Path(roundedRect: CGRect(x: cx - 11, y: h * 0.20, width: 22, height: 6), cornerRadius: 2),
                     with: .color(gold))
            for i in 0..<22 {
                let px = CGFloat((i * 79) % Int(w)), py = CGFloat((i * 43) % Int(h * 0.75))
                ctx.fill(Path(CGRect(x: px, y: py, width: 2.5, height: 5)), with: .color(tint.opacity(0.45)))
            }

        case .presse:
            glow(w * 0.5, h * 0.28, w * 0.5, 0.26)
            ground(&ctx, y: h * 0.86, w: w, h: h, color: ink)
            for i in 0..<7 {
                let x = w * 0.12 + CGFloat(i) * w * 0.12
                let top = h * (0.34 + Double(i % 3) * 0.09)
                var stick = Path()
                stick.move(to: CGPoint(x: x, y: h))
                stick.addLine(to: CGPoint(x: x + 5, y: top + 12))
                ctx.stroke(stick, with: .color(ink), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                ctx.fill(Path(roundedRect: CGRect(x: x - 6, y: top, width: 14, height: 19), cornerRadius: 6),
                         with: .color(i % 2 == 0 ? tint.opacity(0.9) : Color.white.opacity(0.75)))
            }
            for i in 0..<3 {
                let x = w * (0.22 + Double(i) * 0.28), y = h * 0.18
                var flash = Path()
                flash.move(to: CGPoint(x: x, y: y - 11))
                flash.addLine(to: CGPoint(x: x + 4, y: y - 4))
                flash.addLine(to: CGPoint(x: x + 11, y: y))
                flash.addLine(to: CGPoint(x: x + 4, y: y + 4))
                flash.addLine(to: CGPoint(x: x, y: y + 11))
                flash.addLine(to: CGPoint(x: x - 4, y: y + 4))
                flash.addLine(to: CGPoint(x: x - 11, y: y))
                flash.addLine(to: CGPoint(x: x - 4, y: y - 4))
                flash.closeSubpath()
                ctx.fill(flash, with: .color(.white.opacity(0.8)))
            }
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.1, width: w * 0.2, height: h * 0.9), strength: 0.10)

        case .argent:
            glow(w * 0.72, h * 0.24, w * 0.45, 0.26)
            ground(&ctx, y: h * 0.62, w: w, h: h, color: ink)
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.10, y: h * 0.42, width: w * 0.42, height: h * 0.24),
                          cornerRadius: 3), with: .color(.white.opacity(0.88)))
            for i in 0..<4 {
                var line = Path()
                line.move(to: CGPoint(x: w * 0.14, y: h * (0.48 + Double(i) * 0.045)))
                line.addLine(to: CGPoint(x: w * (0.44 - Double(i % 2) * 0.09), y: h * (0.48 + Double(i) * 0.045)))
                ctx.stroke(line, with: .color(ink.opacity(0.55)), lineWidth: 2)
            }
            var pen = Path()
            pen.move(to: CGPoint(x: w * 0.34, y: h * 0.70))
            pen.addLine(to: CGPoint(x: w * 0.56, y: h * 0.40))
            ctx.stroke(pen, with: .color(ink), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            for i in 0..<5 {
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.74 - 28, y: h * 0.86 - CGFloat(i) * 8 - 9,
                                                width: 56, height: 15)),
                         with: .color(i % 2 == 0 ? tint : tint.opacity(0.6)))
            }
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.1, width: w * 0.16, height: h * 0.9), strength: 0.09)

        case .famille:
            glow(w * 0.34, h * 0.55, w * 0.4, 0.32)
            ground(&ctx, y: h * 0.86, w: w, h: h, color: ink)
            var roof = Path()
            roof.move(to: CGPoint(x: w * 0.06, y: h * 0.50))
            roof.addLine(to: CGPoint(x: w * 0.34, y: h * 0.18))
            roof.addLine(to: CGPoint(x: w * 0.62, y: h * 0.50))
            roof.closeSubpath()
            ctx.fill(roof, with: .color(ink))
            ctx.fill(Path(CGRect(x: w * 0.12, y: h * 0.50, width: w * 0.44, height: h * 0.36)), with: .color(ink))
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.56, width: 30, height: 24), cornerRadius: 3),
                     with: .color(tint.opacity(0.9)))
            figure(&ctx, x: w * 0.78, ground: h * 0.88, height: h * 0.56, "debout")
            figure(&ctx, x: w * 0.88, ground: h * 0.88, height: h * 0.38, "debout", flip: true)
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.1, width: w * 0.14, height: h * 0.9), strength: 0.09)

        case .infirmerie:
            glow(w * 0.42, h * 0.34, w * 0.45, 0.28)
            ground(&ctx, y: h * 0.86, w: w, h: h, color: ink)
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.10, y: h * 0.54, width: w * 0.62, height: 13),
                          cornerRadius: 4), with: .color(.white.opacity(0.82)))
            for x in [w * 0.16, w * 0.62] {
                ctx.fill(Path(CGRect(x: x, y: h * 0.67, width: 6, height: h * 0.19)), with: .color(ink))
            }
            var leg = Path()
            leg.move(to: CGPoint(x: w * 0.18, y: h * 0.50))
            leg.addLine(to: CGPoint(x: w * 0.50, y: h * 0.42))
            ctx.stroke(leg, with: .color(ink), style: StrokeStyle(lineWidth: 15, lineCap: .round))
            ctx.stroke(leg, with: .color(.white.opacity(0.85)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            let cx2 = w * 0.86, cy2 = h * 0.26
            ctx.fill(Path(CGRect(x: cx2 - 4.5, y: cy2 - 15, width: 9, height: 30)), with: .color(tint))
            ctx.fill(Path(CGRect(x: cx2 - 15, y: cy2 - 4.5, width: 30, height: 9)), with: .color(tint))
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.1, width: w * 0.14, height: h * 0.9), strength: 0.09)

        case .voyage:
            glow(w * 0.5, h * 0.22, w * 0.55, 0.26)
            ground(&ctx, y: h * 0.78, w: w, h: h, color: ink)
            var body = Path()
            body.move(to: CGPoint(x: w * 0.12, y: h * 0.44))
            body.addLine(to: CGPoint(x: w * 0.62, y: h * 0.30))
            body.addLine(to: CGPoint(x: w * 0.68, y: h * 0.38))
            body.addLine(to: CGPoint(x: w * 0.34, y: h * 0.50))
            body.closeSubpath()
            ctx.fill(body, with: .color(.white.opacity(0.9)))
            var wing = Path()
            wing.move(to: CGPoint(x: w * 0.40, y: h * 0.38))
            wing.addLine(to: CGPoint(x: w * 0.50, y: h * 0.10))
            wing.addLine(to: CGPoint(x: w * 0.58, y: h * 0.36))
            wing.closeSubpath()
            ctx.fill(wing, with: .color(tint))
            figure(&ctx, x: w * 0.84, ground: h * 0.92, height: h * 0.5, "marche")
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.5, width: w * 0.3, height: h * 0.5), strength: 0.10)

        case .solitude:
            glow(w * 0.66, h * 0.30, w * 0.5, 0.22)
            ground(&ctx, y: h * 0.84, w: w, h: h, color: ink)
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.52, y: h * 0.66, width: w * 0.40, height: 9),
                          cornerRadius: 2), with: .color(Color(red: 0.09, green: 0.204, blue: 0.235)))
            figure(&ctx, x: w * 0.70, ground: h * 0.92, height: h * 0.70, "assis")
            var line = Path()
            line.move(to: CGPoint(x: -10, y: h * 0.84))
            line.addLine(to: CGPoint(x: w + 10, y: h * 0.84))
            ctx.stroke(line, with: .color(tint.opacity(0.35)), lineWidth: 2)
            screentone(&ctx, rect: CGRect(x: 2, y: h * 0.1, width: w * 0.34, height: h * 0.72), strength: 0.10)

        case .nuit:
            glow(w * 0.5, h * 0.30, w * 0.5, 0.22)
            for i in 0..<7 {
                let bw = w / 7.4
                let bh = h * (0.30 + Double((i * 37) % 5) * 0.10)
                let x = CGFloat(i) * (w / 7) + 3
                ctx.fill(Path(CGRect(x: x, y: h * 0.86 - bh, width: bw, height: bh)), with: .color(ink))
                for row in 0..<3 {
                    for col in 0..<2 {
                        guard (i * 7 + row * 3 + col) % 3 != 0 else { continue }
                        ctx.fill(Path(CGRect(x: x + 6 + CGFloat(col) * 12,
                                             y: h * 0.86 - bh + 8 + CGFloat(row) * 12,
                                             width: 6, height: 6)),
                                 with: .color(tint.opacity(0.75)))
                    }
                }
            }
            ground(&ctx, y: h * 0.86, w: w, h: h, color: ink)
            for i in 0..<9 {
                var rain = Path()
                let x = CGFloat(i) * (w / 9) + 12
                rain.move(to: CGPoint(x: x, y: h * 0.1))
                rain.addLine(to: CGPoint(x: x - 8, y: h * 0.5))
                ctx.stroke(rain, with: .color(.white.opacity(0.07)), lineWidth: 1.5)
            }
            figure(&ctx, x: w * 0.5, ground: h * 0.99, height: h * 0.5, "marche")
        }
    }
}
