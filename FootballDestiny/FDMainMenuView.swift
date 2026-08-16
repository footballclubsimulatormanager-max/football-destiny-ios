import SwiftUI
import UIKit

struct FDMainMenuView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var showAbout = false
    @State private var showHistorique = false
    @State private var showBoutique = false
    @State private var showDefis = false
    @State private var showClassement = false
    @State private var showRegles = false

    var body: some View {
        ZStack {
            FDTheme.backgroundGradient
                .ignoresSafeArea()

            FDTheme.ambientGlow

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(spacing: 22) {
                        greetingHeader
                            .fdAppear()

                        // Two blocks, deliberately different: playing a career, then
                        // everything that surrounds it. The break is visual, not just
                        // spacing — full-width rows above, a compact grid below.
                        VStack(spacing: 12) {
                            menuSectionLabel("Jouer", icon: "sportscourt.fill")

                            FDMenuRow(
                                icon: "sportscourt.fill",
                                iconTint: FDTheme.primary,
                                title: "Nouvelle carrière",
                                subtitle: "Commencer une nouvelle histoire",
                                disabled: false
                            ) {
                                FDHaptics.tap()
                                screen = .creation
                            }
                            .fdAppear(delay: 0.05)

                            FDMenuRow(
                                icon: "play.fill",
                                iconTint: FDTheme.success,
                                title: "Continuer",
                                subtitle: engine.hasSave() ? "Reprendre ta carrière en cours" : "Aucune carrière en cours",
                                disabled: !engine.hasSave()
                            ) {
                                FDHaptics.tap()
                                if engine.loadGame() { screen = .game }
                            }
                            .fdAppear(delay: 0.10)
                            .modifier(FDConditionalPulse(active: engine.hasSave()))

                            FDMenuRow(
                                icon: "trophy.fill",
                                iconTint: FDTheme.amber,
                                title: "Défi Gloire du Passé",
                                subtitle: "\(engine.conqueredLegendIDs.count)/\(FDLegendChallenges.count) légendes conquises",
                                disabled: false
                            ) {
                                FDHaptics.tap()
                                showDefis = true
                            }
                            .fdAppear(delay: 0.15)
                        }

                        VStack(spacing: 10) {
                            menuSectionLabel("Ton univers", icon: "square.grid.2x2.fill")

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                FDMenuTile(
                                    icon: "cart.fill",
                                    tint: FDTheme.blueGlow,
                                    title: "Boutique",
                                    detail: "\(engine.legendCoins) pièce(s)",
                                    disabled: false
                                ) {
                                    FDHaptics.tap()
                                    showBoutique = true
                                }
                                .fdAppear(delay: 0.20)

                                FDMenuTile(
                                    icon: "list.number",
                                    tint: FDTheme.warning,
                                    title: "Classement",
                                    detail: engine.archivedCareers.isEmpty ? "Vide" : "Top 100",
                                    disabled: engine.archivedCareers.isEmpty
                                ) {
                                    FDHaptics.tap()
                                    showClassement = true
                                }
                                .fdAppear(delay: 0.24)

                                FDMenuTile(
                                    icon: "clock.arrow.circlepath",
                                    tint: FDTheme.accentTeal,
                                    title: "Historique",
                                    detail: engine.archivedCareers.isEmpty
                                        ? "Aucune carrière"
                                        : "\(engine.archivedCareers.count) carrière(s)",
                                    disabled: false
                                ) {
                                    FDHaptics.tap()
                                    showHistorique = true
                                }
                                .fdAppear(delay: 0.28)

                                FDMenuTile(
                                    icon: "book.fill",
                                    tint: FDTheme.textMuted,
                                    title: "Règles",
                                    detail: "Comment ça marche",
                                    disabled: false
                                ) {
                                    FDHaptics.tap()
                                    showRegles = true
                                }
                                .fdAppear(delay: 0.32)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                }

                Text("Aucune inscription · Aucun compte · Sauvegarde locale")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAbout) { FDAboutSheet() }
        .sheet(isPresented: $showHistorique) { FDHistoriqueView(engine: engine) }
        .sheet(isPresented: $showBoutique) { FDBoutiqueView(engine: engine) }
        .sheet(isPresented: $showDefis) { FDChallengesView(engine: engine, screen: $screen) }
        .sheet(isPresented: $showClassement) { FDClassementView(engine: engine) }
        .sheet(isPresented: $showRegles) { FDReglesView() }
    }

    /// The brand lockup, centred: the mark, then "FCS" in the display italic under a
    /// gradient with "DESTINY" letterspaced beneath it. The info button is overlaid rather
    /// than placed in the row, so it can't pull the lockup off centre.
    private var topBar: some View {
        HStack(spacing: 10) {
            FDLogoBadge(size: 38, corner: 10)

            VStack(alignment: .leading, spacing: -1) {
                Text("FCS")
                    .font(FDFont.display(24))
                    .foregroundStyle(FDTheme.primaryTextGradient)
                Text("DESTINY")
                    .font(FDFont.body(12, black: true))
                    .tracking(5.5)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            Button {
                showAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    private var potentialStarsUnlocked: Int {
        FDPotentialShop.maxAffordableStars(points: engine.lifetimePoints)
    }

    /// Greets by the in-progress player's first name when there's a career underway, otherwise
    /// a generic welcome — there's no login/account, so this is the only "who's playing" signal.
    private var greetingName: String? {
        guard let p = engine.player, !p.retired else { return nil }
        return p.firstName
    }

    private var statusLine: (icon: String, tint: Color, text: String) {
        if let name = greetingName {
            return ("arrow.uturn.forward.circle.fill", FDTheme.success, "\(name) t'attend — reprends là où tu t'es arrêté")
        }
        if engine.lifetimePoints > 0 {
            return ("trophy.fill", FDTheme.amber, "\(engine.lifetimePoints) points de carrière cumulés")
        }
        return ("sparkles", FDTheme.primary, "Prêt à écrire ta première légende")
    }

    /// Compact identity block — small logo, a short label, a personal greeting and a one-line
    /// status — in place of the previous full-width hero card with a giant centered logo.
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SIMULATEUR DE CARRIÈRE")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(FDTheme.primary)
                Text(greetingName.map { "Bonjour, \($0)" } ?? "Bonjour")
                    .font(FDFont.display(25))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                Image(systemName: statusLine.icon)
                    .font(.system(size: 14, weight: .bold))
                Text(statusLine.text)
                    .font(.fdRounded(.footnote, weight: .semibold))
            }
            .foregroundStyle(statusLine.tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(statusLine.tint.opacity(0.14)))

            HStack(spacing: 3) {
                ForEach(0..<FDPotentialShop.maxStars, id: \.self) { i in
                    Image(systemName: i < potentialStarsUnlocked ? "star.fill" : "star")
                        .font(.system(size: 15))
                        .foregroundStyle(i < potentialStarsUnlocked ? FDTheme.amber : Color.white.opacity(0.22))
                        .scaleEffect(i < potentialStarsUnlocked ? 1 : 0.85)
                        .fdAppear(delay: 0.3 + Double(i) * 0.04)
                }
                Text("Potentiel de départ")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.leading, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}


/// The thin heading that separates the two halves of the menu.
private func menuSectionLabel(_ text: String, icon: String) -> some View {
    HStack(spacing: 7) {
        Image(systemName: icon)
            .font(.system(size: 11, weight: .bold))
        Text(text.uppercased())
            .font(FDFont.body(13, black: true))
            .tracking(1.4)
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
    }
    .foregroundStyle(.white.opacity(0.45))
    .padding(.horizontal, 2)
}

/// Compact square used by the second half of the menu: everything that surrounds a career
/// rather than being one, so it reads as a different kind of destination.
private struct FDMenuTile: View {
    let icon: String
    let tint: Color
    let title: String
    let detail: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(FDFont.body(15, black: true))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(FDRowButtonStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }
}

private struct FDMenuRow: View {
    let icon: String
    let iconTint: Color
    let title: String
    let subtitle: String
    var badge: (text: String, icon: String, tint: Color)? = nil
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                FDIconBadge(symbol: icon, tint: iconTint, size: 44, isSystemImage: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(FDFont.display(19)).foregroundStyle(.white)
                    Text(subtitle).font(.footnote).foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                if let badge {
                    HStack(spacing: 4) {
                        Image(systemName: badge.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(badge.text)
                            .font(FDFont.mono(14, bold: true))
                    }
                    .foregroundStyle(badge.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(badge.tint.opacity(0.16)))
                }

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(FDRowButtonStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }
}

/// Wraps a view in `.fdPulse()` only when `active`, so the attention-drawing glow never
/// shows on the "Continuer" row before a save actually exists.
private struct FDConditionalPulse: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.fdPulse()
        } else {
            content
        }
    }
}

struct FDAboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("FCS-Destiny est un prototype de simulateur de carrière de footballeur : formation (2 saisons maximum en U16/U18), entraînements, vestiaire, contrats, blessures, sélection nationale, transferts, jusqu'à la retraite — forcée à 43 ans, ou à tout moment de ton choix depuis l'onglet Options.")
                        .font(.body)
                        .fdCard()

                    VStack(alignment: .leading, spacing: 10) {
                        FDSectionLabel("Un rythme resserré")
                        Label("Une poignée de choix marquants par saison — le reste se joue en coulisses", systemImage: "book.fill")
                    }
                    .font(.body)
                    .fdCard()

                    VStack(alignment: .leading, spacing: 10) {
                        FDSectionLabel("Deux monnaies, deux usages")
                        Label("Points de carrière cumulés : dépensés en étoiles de potentiel au lancement d'une nouvelle carrière.", systemImage: "trophy.fill")
                        Label("Pièces : gagnées seulement pour les grandes carrières, à dépenser dans la Boutique et le Défi Gloire du Passé.", systemImage: "seal.fill")
                    }
                    .font(.body)
                    .fdCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Aucune inscription, aucun compte, aucune donnée envoyée en ligne : tout est joué et sauvegardé directement sur cet appareil.")
                        Text("Les clubs utilisent des villes et championnats réels ; aucun écusson, maillot ou nom de compétition officiel n'est reproduit.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fdCard()
                }
                .padding()
            }
            .background(FDTheme.bg)
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

enum FDHaptics {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
