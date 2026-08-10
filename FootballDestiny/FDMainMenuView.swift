import SwiftUI
import UIKit

struct FDMainMenuView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var showAbout = false
    @State private var appear = false

    var body: some View {
        ZStack {
            FDTheme.backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(FDTheme.gold.opacity(0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 140, y: -280)

            Circle()
                .fill(FDTheme.violetGlow.opacity(0.30))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -150, y: 300)

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
                                iconTint: .mint,
                                title: "Nouvelle carrière",
                                subtitle: "Commencer une nouvelle histoire",
                                disabled: false
                            ) {
                                FDHaptics.tap()
                                screen = .creation
                            }

                            FDMenuRow(
                                icon: "play.fill",
                                iconTint: FDTheme.gold,
                                title: "Continuer",
                                subtitle: engine.hasSave() ? "Reprendre ta carrière en cours" : "Aucune carrière en cours",
                                disabled: !engine.hasSave()
                            ) {
                                FDHaptics.tap()
                                if engine.loadGame() { screen = .game }
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
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(FDTheme.goldTextGradient)
                    Image(systemName: "soccerball")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(FDTheme.ink)
                }
                .frame(width: 34, height: 34)

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

    private var heroCard: some View {
        VStack(spacing: 10) {
            Text("SIMULATEUR DE CARRIÈRE")
                .font(.caption.weight(.bold))
                .tracking(4)
                .foregroundStyle(FDTheme.gold)

            VStack(spacing: 2) {
                Text("FCS")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("DESTINY")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(FDTheme.goldTextGradient)
            }
            .shadow(color: .black.opacity(0.3), radius: 14, y: 6)

            Text("Écris ta carrière. Vis ta légende.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))
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
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconTint.opacity(0.18))
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconTint)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.white)
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
                        FDSectionLabel("Deux styles de carrière")
                        Label("Narratif — tu vis chaque évènement", systemImage: "book.fill")
                        Label("Express — seuls les moments clés s'affichent", systemImage: "forward.fill")
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
            .background(Color(.systemGroupedBackground))
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
