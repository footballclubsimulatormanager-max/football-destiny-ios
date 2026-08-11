import SwiftUI

// MARK: - Historique (past careers)

struct FDHistoriqueView: View {
    @ObservedObject var engine: FDGameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if engine.archivedCareers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Aucune carrière terminée pour l'instant.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(engine.archivedCareers.enumerated()), id: \.offset) { _, p in
                                NavigationLink {
                                    ScrollView {
                                        FDCareerSummaryCard(player: p)
                                            .padding()
                                    }
                                    .background(FDTheme.bg)
                                    .navigationTitle("\(p.firstName) \(p.lastName)")
                                    .navigationBarTitleDisplayMode(.inline)
                                } label: {
                                    FDHistoriqueRow(player: p)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(FDTheme.bg)
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct FDHistoriqueRow: View {
    let player: FDPlayer

    var body: some View {
        HStack(spacing: 12) {
            FDIconBadge(symbol: "person.fill", tint: FDTheme.primary, size: 40, isSystemImage: true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(player.firstName) \(player.lastName)").font(FDFont.body(15, black: true))
                Text("\(player.nationality) · \(player.position.rawValue) · retraité à \(player.age) ans")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.careerGoals)").font(FDFont.mono(15, bold: true)).foregroundStyle(FDTheme.amber)
                Text("buts").font(.caption2).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.3))
        }
        .fdCard()
    }
}

// MARK: - Boutique (permanent competences)

struct FDBoutiqueView: View {
    @ObservedObject var engine: FDGameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("🪙 \(engine.legendCoins) pièces").font(FDFont.display(20))
                        Spacer()
                    }
                    .fdCard()

                    Text("Gagne des pièces en terminant des carrières — jusqu'à 10 pour une carrière parfaite (Ballon d'Or, titre international, Soulier d'Or). Chaque compétence achetée reste acquise pour toutes tes futures carrières.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        ForEach(FDCompetences) { c in
                            FDCompetenceRow(
                                competence: c,
                                owned: engine.ownedCompetenceIDs.contains(c.id),
                                canAfford: engine.legendCoins >= c.cost
                            ) {
                                FDHaptics.tap()
                                engine.purchaseCompetence(c.id)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(FDTheme.bg)
            .navigationTitle("Boutique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct FDCompetenceRow: View {
    let competence: FDCompetence
    let owned: Bool
    let canAfford: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            FDIconBadge(symbol: competence.icon, tint: FDTheme.primary, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(competence.name).font(FDFont.body(15, black: true))
                Text(competence.description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if owned {
                Text("Acquis")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FDTheme.success)
            } else {
                Button(action: action) {
                    Text("🪙 \(competence.cost)")
                        .font(FDFont.body(13, black: true))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(canAfford ? FDTheme.primary : Color.white.opacity(0.08)))
                        .foregroundStyle(canAfford ? FDTheme.ink : .white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)
            }
        }
        .fdCard()
    }
}

// MARK: - Défi Gloire du Passé (fictional legends)

struct FDDefiGloireView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @Environment(\.dismiss) private var dismiss
    @State private var pendingChallenge: FDLegendChallenge?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("🪙 \(engine.legendCoins) pièces").font(FDFont.display(20))
                        Spacer()
                        Text("\(engine.conqueredLegendIDs.count)/\(FDLegendChallenges.count) conquis")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .fdCard()

                    Text("Débloque des légendes fictives — inspirées de grandes carrières, jamais de vrais noms — puis rejoue leur destin en tentant de dépasser leur score.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        ForEach(FDLegendChallenges) { challenge in
                            FDLegendRow(
                                challenge: challenge,
                                unlocked: engine.unlockedLegendIDs.contains(challenge.id),
                                conquered: engine.conqueredLegendIDs.contains(challenge.id),
                                canAfford: engine.legendCoins >= challenge.unlockCost,
                                onUnlock: {
                                    FDHaptics.tap()
                                    engine.unlockLegendChallenge(challenge.id)
                                },
                                onPlay: { pendingChallenge = challenge }
                            )
                        }
                    }
                }
                .padding()
            }
            .background(FDTheme.bg)
            .navigationTitle("Défi Gloire du Passé")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .alert(item: $pendingChallenge) { challenge in
                Alert(
                    title: Text("Lancer ce défi ?"),
                    message: Text(engine.hasSave()
                        ? "Ta carrière en cours sera remplacée par celle de \(challenge.name). Objectif : dépasser \(challenge.targetScore) points."
                        : "Tu vas incarner \(challenge.name) — \(challenge.archetype) Objectif : dépasser \(challenge.targetScore) points."),
                    primaryButton: .destructive(Text("Lancer")) {
                        FDHaptics.success()
                        engine.startLegendCareer(challenge)
                        dismiss()
                        screen = .game
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct FDLegendRow: View {
    let challenge: FDLegendChallenge
    let unlocked: Bool
    let conquered: Bool
    let canAfford: Bool
    let onUnlock: () -> Void
    let onPlay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                FDIconBadge(symbol: conquered ? "trophy.fill" : "person.fill.questionmark", tint: conquered ? FDTheme.amber : FDTheme.primary, size: 44, isSystemImage: true)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(challenge.name).font(FDFont.body(15, black: true))
                        if conquered { Text("✅").font(.caption) }
                    }
                    Text("\(challenge.era) · \(challenge.nationality) · \(challenge.position.rawValue)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Text(challenge.archetype)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text("Objectif : \(challenge.targetScore) pts")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FDTheme.gold)
                Spacer(minLength: 8)
                if unlocked {
                    Button(action: onPlay) {
                        Text("Rejouer")
                            .font(FDFont.body(13, black: true))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(FDTheme.primary))
                            .foregroundStyle(FDTheme.ink)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onUnlock) {
                        Text("🪙 \(challenge.unlockCost)")
                            .font(FDFont.body(13, black: true))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(canAfford ? FDTheme.primary : Color.white.opacity(0.08)))
                            .foregroundStyle(canAfford ? FDTheme.ink : .white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAfford)
                }
            }
        }
        .fdCard()
    }
}
