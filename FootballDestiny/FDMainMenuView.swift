import SwiftUI
import UIKit

struct FDMainMenuView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var showAbout = false
    @State private var showHistorique = false
    @State private var showBoutique = false
    @State private var showDefis = false
    @State private var appear = false

    var body: some View {
        ZStack {
            FDTheme.backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(FDTheme.violetGlow.opacity(0.30))
                .frame(width: 320, height: 320)
                .blur(radius: 75)
                .offset(x: 140, y: -280)

            Circle()
                .fill(FDTheme.blueGlow.opacity(0.26))
                .frame(width: 280, height: 280)
                .blur(radius: 75)
                .offset(x: -150, y: 300)

            Circle()
                .fill(FDTheme.violetGlow.opacity(0.12))
                .frame(width: 420, height: 420)
                .blur(radius: 90)

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(spacing: 20) {
                        heroCard
                            .scaleEffect(appear ? 1 : 0.94)
                            .opacity(appear ? 1 : 0)

                        VStack(spacing: 12) {
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

                            FDMenuRow(
                                icon: "play.fill",
                                iconTint: FDTheme.accentTeal,
                                title: "Continuer",
                                subtitle: engine.hasSave() ? "Reprendre ta carrière en cours" : "Aucune carrière en cours",
                                disabled: !engine.hasSave()
                            ) {
                                FDHaptics.tap()
                                if engine.loadGame() { screen = .game }
                            }

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

                            FDMenuRow(
                                icon: "cart.fill",
                                iconTint: FDTheme.amber,
                                title: "Boutique",
                                subtitle: "🪙 \(engine.legendCoins) pièce(s) — compétences permanentes",
                                disabled: false
                            ) {
                                FDHaptics.tap()
                                showBoutique = true
                            }

                            FDMenuRow(
                                icon: "clock.arrow.circlepath",
                                iconTint: FDTheme.accentTeal,
                                title: "Historique",
                                subtitle: engine.archivedCareers.isEmpty ? "Aucune carrière terminée" : "\(engine.archivedCareers.count) carrière(s) terminée(s)",
                                disabled: false
                            ) {
                                FDHaptics.tap()
                                showHistorique = true
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 12)
                }

                Text("Aucune inscription · Aucun compte · Sauvegarde locale")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
        .sheet(isPresented: $showAbout) { FDAboutSheet() }
        .sheet(isPresented: $showHistorique) { FDHistoriqueView(engine: engine) }
        .sheet(isPresented: $showBoutique) { FDBoutiqueView(engine: engine) }
        .sheet(isPresented: $showDefis) { FDDefiGloireView(engine: engine, screen: $screen) }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                FDLogoBadge(size: 34, corner: 9)

                Text("FCS-DESTINY")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Button {
                showAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var potentialStarsUnlocked: Int {
        FDPotentialShop.maxAffordableStars(points: engine.lifetimePoints)
    }

    private var heroCard: some View {
        VStack(spacing: 14) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 168, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)

            Text("SIMULATEUR DE CARRIÈRE")
                .font(.caption.weight(.bold))
                .tracking(4)
                .foregroundStyle(FDTheme.primary)

            Text("Écris ta carrière. Vis ta légende.")
                .font(FDFont.body(15))
                .foregroundStyle(.white.opacity(0.65))

            if engine.lifetimePoints > 0 {
                HStack(spacing: 5) {
                    Text("🏆")
                    Text("\(engine.lifetimePoints) points de carrière cumulés")
                        .font(.fdRounded(.caption, weight: .semibold))
                }
                .foregroundStyle(FDTheme.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(FDTheme.gold.opacity(0.14)))
                .padding(.top, 4)
            }

            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    ForEach(0..<FDPotentialShop.maxStars, id: \.self) { i in
                        Image(systemName: i < potentialStarsUnlocked ? "star.fill" : "star")
                            .font(.system(size: 15))
                            .foregroundStyle(i < potentialStarsUnlocked ? FDTheme.amber : Color.white.opacity(0.25))
                    }
                }
                Text("Potentiel de départ — progresse avec tes carrières cumulées")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct FDMenuRow: View {
    let icon: String
    let iconTint: Color
    let title: String
    let subtitle: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                FDIconBadge(symbol: icon, tint: iconTint, size: 44, isSystemImage: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(FDFont.display(19)).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
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
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }
}

struct FDAboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("FCS-Destiny est un prototype de simulateur de carrière de footballeur : formation (2 saisons maximum en U16/U18), entraînements, vestiaire, contrats, blessures, sélection nationale, transferts, jusqu'à la retraite — forcée à 43 ans, ou à tout moment de ton choix depuis l'onglet Options.")
                        .font(.subheadline)
                        .fdCard()

                    VStack(alignment: .leading, spacing: 10) {
                        FDSectionLabel("Un rythme resserré")
                        Label("Une poignée de choix marquants par saison — le reste se joue en coulisses", systemImage: "book.fill")
                    }
                    .font(.subheadline)
                    .fdCard()

                    VStack(alignment: .leading, spacing: 10) {
                        FDSectionLabel("Deux monnaies, deux usages")
                        Label("🏆 Points de carrière cumulés : dépensés en étoiles de potentiel au lancement d'une nouvelle carrière.", systemImage: "star.fill")
                        Label("🪙 Pièces : gagnées seulement pour les grandes carrières, à dépenser dans la Boutique et le Défi Gloire du Passé.", systemImage: "cart.fill")
                    }
                    .font(.subheadline)
                    .fdCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Aucune inscription, aucun compte, aucune donnée envoyée en ligne : tout est joué et sauvegardé directement sur cet appareil.")
                        Text("Les clubs utilisent des villes et championnats réels ; aucun écusson, maillot ou nom de compétition officiel n'est reproduit.")
                    }
                    .font(.footnote)
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
