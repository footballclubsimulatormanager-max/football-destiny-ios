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
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header: total stats across careers
                            let totalGoals = engine.archivedCareers.reduce(0) { $0 + $1.careerGoals }
                            let totalApps = engine.archivedCareers.reduce(0) { $0 + $1.careerApps }

                            HStack(spacing: 0) {
                                VStack(spacing: 2) {
                                    Text("\(engine.archivedCareers.count)")
                                        .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.amber)
                                    Text("CARRIÈRES")
                                        .font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                                VStack(spacing: 2) {
                                    Text("\(totalGoals)")
                                        .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.success)
                                    Text("BUTS TOTAUX")
                                        .font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                                VStack(spacing: 2) {
                                    Text("\(totalApps)")
                                        .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.primary)
                                    Text("MATCHS TOTAUX")
                                        .font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 14)
                            .background(FDTheme.card)

                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                            ForEach(Array(engine.archivedCareers.enumerated()), id: \.offset) { idx, p in
                                NavigationLink {
                                    ScrollView {
                                        FDCareerSummaryCard(player: p)
                                            .padding()
                                    }
                                    .background(FDTheme.bg)
                                    .navigationTitle("\(p.firstName) \(p.lastName)")
                                    .navigationBarTitleDisplayMode(.inline)
                                } label: {
                                    FDHistoriqueRow(player: p, index: engine.archivedCareers.count - idx)
                                }
                                .buttonStyle(.plain)
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                        .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
                        .padding(.horizontal, 14)
                        .padding(.bottom, 20)
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
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(FDTheme.primary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text("\(index)")
                    .font(FDFont.mono(16, bold: true))
                    .foregroundStyle(FDTheme.primary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(player.firstName) \(player.lastName)")
                    .font(FDFont.body(14, black: true))
                    .foregroundStyle(FDTheme.textPrimary)
                Text("\(player.nationality) · \(player.position.rawValue) · retraité à \(player.age) ans")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.careerGoals)")
                    .font(FDFont.mono(16, bold: true))
                    .foregroundStyle(FDTheme.amber)
                Text("buts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

// MARK: - Boutique (permanent competences)

struct FDBoutiqueView: View {
    @ObservedObject var engine: FDGameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Coins balance
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(FDTheme.amber.opacity(0.15)).frame(width: 44, height: 44)
                                Text("🪙").font(.system(size: 22))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(engine.legendCoins) pièces")
                                    .font(FDFont.display(20))
                                    .foregroundStyle(FDTheme.amber)
                                Text("Solde disponible")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        Text("Gagne des pièces en terminant des carrières — jusqu'à 10 pour une carrière parfaite. Chaque compétence achetée reste acquise pour toutes tes futures carrières.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(14)
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(FDTheme.amber.opacity(0.2), lineWidth: 1))

                    // Compétences
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(FDTheme.amber)
                            Text("COMPÉTENCES PERMANENTES")
                                .font(FDFont.body(11, black: true))
                                .foregroundStyle(FDTheme.amber)
                            Spacer()
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(FDTheme.amber.opacity(0.08))

                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                        ForEach(Array(engine.permanentSkills.enumerated()), id: \.offset) { idx, skill in
                            FDSkillRow(
                                skill: skill,
                                canAfford: engine.legendCoins >= skill.cost,
                                owned: engine.unlockedSkills.contains(skill.id),
                                onBuy: { engine.buySkill(skill) }
                            )
                            if idx < engine.permanentSkills.count - 1 {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
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

private struct FDSkillRow: View {
    let skill: FDPermanentSkill
    let canAfford: Bool
    let owned: Bool
    let onBuy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(owned ? FDTheme.amber.opacity(0.15) : FDTheme.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: owned ? "checkmark.seal.fill" : skill.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(owned ? FDTheme.amber : FDTheme.primary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.name)
                    .font(FDFont.body(14, black: true))
                    .foregroundStyle(FDTheme.textPrimary)
                Text(skill.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            if owned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(FDTheme.success)
                    .font(.title3)
            } else {
                Button(action: onBuy) {
                    Text("🪙 \(skill.cost)")
                        .font(FDFont.body(12, black: true))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(canAfford ? FDTheme.primary : Color.white.opacity(0.07)))
                        .foregroundStyle(canAfford ? .white : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Challenges

struct FDChallengesView: View {
    @ObservedObject var engine: FDGameEngine
    var screen: Binding<FDScreen>? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Summary
                    let total = engine.challenges.count
                    let conquered = engine.challenges.filter { engine.conqueredChallenges.contains($0.id) }.count
                    let unlocked = engine.challenges.filter { engine.unlockedChallenges.contains($0.id) }.count

                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            VStack(spacing: 2) {
                                Text("\(total)")
                                    .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.primary)
                                Text("TOTAL")
                                    .font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                            VStack(spacing: 2) {
                                Text("\(unlocked)")
                                    .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.warning)
                                Text("DÉBLOQUÉS")
                                    .font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                            VStack(spacing: 2) {
                                Text("\(conquered)")
                                    .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.amber)
                                Text("CONQUIS")
                                    .font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 14)
                        .background(FDTheme.card)

                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.white.opacity(0.07))
                                Rectangle()
                                    .fill(LinearGradient(colors: [FDTheme.amber, FDTheme.primary], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: total > 0 ? geo.size.width * CGFloat(conquered) / CGFloat(total) : 0)
                            }
                        }
                        .frame(height: 3)
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    // Challenge list
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .font(.caption.weight(.bold)).foregroundStyle(FDTheme.amber)
                            Text("DÉFIS LÉGENDAIRES")
                                .font(FDFont.body(11, black: true)).foregroundStyle(FDTheme.amber)
                            Spacer()
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(FDTheme.amber.opacity(0.08))

                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                        ForEach(Array(engine.challenges.enumerated()), id: \.offset) { idx, challenge in
                            let isConquered = engine.conqueredChallenges.contains(challenge.id)
                            let isUnlocked = engine.unlockedChallenges.contains(challenge.id)
                            let canAfford = engine.legendCoins >= challenge.unlockCost

                            FDChallengeRow(
                                challenge: challenge,
                                conquered: isConquered,
                                unlocked: isUnlocked,
                                canAfford: canAfford,
                                onUnlock: { engine.unlockChallenge(challenge) },
                                onPlay: {
                                    engine.startChallenge(challenge)
                                    screen?.wrappedValue = .game
                                    dismiss()
                                }
                            )
                            if idx < engine.challenges.count - 1 {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
            .background(FDTheme.bg)
            .navigationTitle("Défis")
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

private struct FDChallengeRow: View {
    let challenge: FDChallenge
    let conquered: Bool
    let unlocked: Bool
    let canAfford: Bool
    let onUnlock: () -> Void
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(conquered ? FDTheme.amber.opacity(0.15) : FDTheme.primary.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: conquered ? "trophy.fill" : "person.fill.questionmark")
                    .font(.system(size: 18))
                    .foregroundStyle(conquered ? FDTheme.amber : FDTheme.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(challenge.name)
                        .font(FDFont.body(14, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                    if conquered {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(FDTheme.amber)
                    }
                }
                Text("\(challenge.era) · \(challenge.nationality) · \(challenge.position.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(challenge.archetype)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 8))
                        .foregroundStyle(FDTheme.warning)
                    Text("Objectif : \(challenge.targetScore) pts")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(FDTheme.warning)
                }
            }

            Spacer(minLength: 4)

            if unlocked {
                Button(action: onPlay) {
                    Text("Rejouer")
                        .font(FDFont.body(12, black: true))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(FDTheme.primary))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onUnlock) {
                    Text("🪙 \(challenge.unlockCost)")
                        .font(FDFont.body(12, black: true))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(canAfford ? FDTheme.amber.opacity(0.85) : Color.white.opacity(0.07)))
                        .foregroundStyle(canAfford ? .black : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
