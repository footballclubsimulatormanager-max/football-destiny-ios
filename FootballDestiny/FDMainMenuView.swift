import SwiftUI
import UIKit

struct FDMainMenuView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var showAbout = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.18), Color(.systemBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.accentColor.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 30)
                .offset(x: 120, y: -260)

            VStack(spacing: 0) {
                Spacer(minLength: 60)

                VStack(spacing: 10) {
                    Text("SIMULATEUR DE CARRIÈRE")
                        .font(.caption.weight(.bold))
                        .tracking(3)
                        .foregroundStyle(Color.accentColor)

                    VStack(spacing: 0) {
                        Text("FCS")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("DESTINY")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                    }
                    .multilineTextAlignment(.center)

                    Text("Écris ta carrière. Vis ta légende.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        FDHaptics.tap()
                        screen = .creation
                    } label: {
                        Label("Nouvelle carrière", systemImage: "sportscourt.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)

                    Button {
                        FDHaptics.tap()
                        if engine.loadGame() { screen = .game }
                    } label: {
                        Label("Continuer", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!engine.hasSave())

                    Button {
                        showAbout = true
                    } label: {
                        Label("À propos", systemImage: "info.circle")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                Text("Aucune inscription · Aucun compte · Sauvegarde locale")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showAbout) { FDAboutSheet() }
    }
}

struct FDAboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("FCS-Destiny est un prototype de simulateur de carrière de footballeur : formation (2 saisons maximum en U16/U18), entraînements, vestiaire, contrats, blessures, sélection nationale, transferts, jusqu'à la retraite — forcée à 43 ans, ou à tout moment de ton choix depuis l'onglet Options.")
                }
                Section("Deux styles de carrière") {
                    Label("Narratif — tu vis chaque évènement", systemImage: "book.fill")
                    Label("Express — seuls les moments clés s'affichent", systemImage: "forward.fill")
                }
                Section {
                    Text("Aucune inscription, aucun compte, aucune donnée envoyée en ligne : tout est joué et sauvegardé directement sur cet appareil.")
                    Text("Les clubs utilisent des villes et championnats réels ; aucun écusson, maillot ou nom de compétition officiel n'est reproduit.")
                }
            }
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
