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
                .fill(FDTheme.gold.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 140, y: -300)

            Circle()
                .fill(Color.accentColor.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: -150, y: 280)

            VStack(spacing: 0) {
                Spacer(minLength: 64)

                VStack(spacing: 14) {
                    Text("SIMULATEUR DE CARRIÈRE")
                        .font(.caption.weight(.bold))
                        .tracking(4)
                        .foregroundStyle(FDTheme.gold)

                    VStack(spacing: 2) {
                        Text("FCS")
                            .font(.system(size: 46, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("DESTINY")
                            .font(.system(size: 46, weight: .heavy, design: .rounded))
                            .foregroundStyle(FDTheme.goldTextGradient)
                    }
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 14, y: 6)

                    Text("Écris ta carrière. Vis ta légende.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .scaleEffect(appear ? 1 : 0.92)
                .opacity(appear ? 1 : 0)

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        FDHaptics.tap()
                        screen = .creation
                    } label: {
                        Label("Nouvelle carrière", systemImage: "sportscourt.fill")
                    }
                    .buttonStyle(FDPrimaryButtonStyle())

                    Button {
                        FDHaptics.tap()
                        if engine.loadGame() { screen = .game }
                    } label: {
                        Label("Continuer", systemImage: "play.fill")
                    }
                    .buttonStyle(FDSecondaryDarkButtonStyle())
                    .disabled(!engine.hasSave())
                    .opacity(engine.hasSave() ? 1 : 0.4)

                    Button {
                        showAbout = true
                    } label: {
                        Label("À propos", systemImage: "info.circle")
                            .font(.subheadline)
                    }
                    .buttonStyle(FDGhostButtonStyle())
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 16)

                Text("Aucune inscription · Aucun compte · Sauvegarde locale")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 20)
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
        .sheet(isPresented: $showAbout) { FDAboutSheet() }
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
