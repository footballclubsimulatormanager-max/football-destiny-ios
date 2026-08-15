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
                                .buttonStyle(FDRowButtonStyle())
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
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(FDTheme.primary.opacity(0.12))
                    .frame(width: 32, height: 32)
                Text("\(index)")
                    .font(FDFont.mono(13, bold: true))
                    .foregroundStyle(FDTheme.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(player.firstName) \(player.lastName)")
                    .font(FDFont.body(14, black: true))
                    .foregroundStyle(FDTheme.textPrimary)
                Text("\(fdFlag(for: player.nationality)) \(player.position.rawValue) · retraité à \(player.age) ans")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Career totals at a glance, not just goals.
                HStack(spacing: 10) {
                    FDMiniStat(value: "\(player.careerGoals)", label: "buts", color: FDTheme.success)
                    FDMiniStat(value: "\(player.careerAssists)", label: "passes", color: FDTheme.primary)
                    FDMiniStat(value: "\(player.careerApps)", label: "matchs", color: FDTheme.accentTeal)
                    if let best = player.history.map(\.avgRating).max(), best > 0 {
                        FDMiniStat(value: String(format: "%.1f", best), label: "note max", color: FDTheme.amber)
                    }
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// Tiny value-over-label pair used in dense list rows.
struct FDMiniStat: View {
    let value: String
    let label: String
    var color: Color = FDTheme.primary

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(FDFont.mono(12, bold: true))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 7.5, weight: .bold))
                .foregroundStyle(.secondary)
        }
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
                                Image(systemName: "seal.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(FDTheme.amber)
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

                    // One continuous list, price bands as inline separators rather than
                    // nested boxes, so the catalogue reads as a single scrolling ladder.
                    VStack(spacing: 0) {
                        ForEach(Array(engine.permanentSkills.enumerated()), id: \.offset) { idx, skill in
                            let previousTier = idx > 0 ? engine.permanentSkills[idx - 1].tier : -1

                            if skill.tier != previousTier,
                               let band = FDMetaTierInfo.all.first(where: { $0.tier == skill.tier }) {
                                HStack(spacing: 5) {
                                    Image(systemName: band.icon)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(band.color)
                                    Text(band.title.uppercased())
                                        .font(.system(size: 9.5, weight: .black))
                                        .foregroundStyle(band.color)
                                    Spacer()
                                    Text(band.subtitle)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(band.color.opacity(0.08))
                                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                            }

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

/// Presentation for the four price bands shared by the Boutique and the Défis, so both
/// screens label progression the same way. Costs themselves live in FDMetaProgression.
struct FDMetaTierInfo {
    let tier: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    static let all: [FDMetaTierInfo] = [
        .init(tier: 1, title: "À portée", subtitle: "~10-15 CARRIÈRES", icon: "leaf.fill", color: FDTheme.success),
        .init(tier: 2, title: "Consolidation", subtitle: "~25-40 CARRIÈRES", icon: "flame.fill", color: FDTheme.primary),
        .init(tier: 3, title: "Exigeant", subtitle: "~50-75 CARRIÈRES", icon: "bolt.fill", color: FDTheme.accentTeal),
        .init(tier: 4, title: "Élite", subtitle: "100+ CARRIÈRES", icon: "crown.fill", color: FDTheme.amber),
    ]
}

private struct FDSkillRow: View {
    let skill: FDPermanentSkill
    let canAfford: Bool
    let owned: Bool
    let onBuy: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(owned ? FDTheme.amber.opacity(0.15) : FDTheme.primary.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: owned ? "checkmark.seal.fill" : skill.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(owned ? FDTheme.amber : FDTheme.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(FDFont.body(13, black: true))
                    .foregroundStyle(FDTheme.textPrimary)
                Text(skill.description)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if owned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(FDTheme.success)
                    .font(.system(size: 16))
            } else {
                Button(action: onBuy) {
                    HStack(spacing: 3) {
                        Image(systemName: "seal.fill").font(.system(size: 9))
                        Text("\(skill.cost)")
                    }
                    .font(FDFont.body(11, black: true))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Capsule().fill(canAfford ? FDTheme.primary : Color.white.opacity(0.07)))
                    .foregroundStyle(canAfford ? .white : .secondary)
                }
                .buttonStyle(FDChoiceButtonStyle())
                .disabled(!canAfford)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

                    // One continuous list for all 50 legends — the price bands are inline
                    // separators, not nested boxes, so the whole thing reads as a single
                    // scrolling ladder rather than four collapsed containers.
                    VStack(spacing: 0) {
                        ForEach(Array(engine.challenges.enumerated()), id: \.offset) { idx, challenge in
                            let previousTier = idx > 0 ? engine.challenges[idx - 1].tier : -1

                            if challenge.tier != previousTier,
                               let band = FDMetaTierInfo.all.first(where: { $0.tier == challenge.tier }) {
                                let items = engine.challenges.filter { $0.tier == band.tier }
                                let done = items.filter { engine.conqueredChallenges.contains($0.id) }.count

                                HStack(spacing: 5) {
                                    Image(systemName: band.icon)
                                        .font(.system(size: 10, weight: .bold)).foregroundStyle(band.color)
                                    Text(band.title.uppercased())
                                        .font(.system(size: 9.5, weight: .black)).foregroundStyle(band.color)
                                    Text(band.subtitle)
                                        .font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(done)/\(items.count)")
                                        .font(FDFont.mono(10, bold: true))
                                        .foregroundStyle(done == items.count ? band.color : .secondary)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(band.color.opacity(0.08))
                                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                            }

                            FDChallengeRow(
                                challenge: challenge,
                                conquered: engine.conqueredChallenges.contains(challenge.id),
                                unlocked: engine.unlockedChallenges.contains(challenge.id),
                                canAfford: engine.legendCoins >= challenge.unlockCost,
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
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(conquered ? FDTheme.amber.opacity(0.15) : FDTheme.primary.opacity(0.1))
                    .frame(width: 34, height: 34)
                Image(systemName: conquered ? "trophy.fill" : "person.fill.questionmark")
                    .font(.system(size: 14))
                    .foregroundStyle(conquered ? FDTheme.amber : FDTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(challenge.name)
                        .font(FDFont.body(13, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                    if conquered {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(FDTheme.amber)
                    }
                }
                Text("\(challenge.era) · \(fdFlag(for: challenge.nationality)) \(challenge.position.rawValue)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(challenge.archetype)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 8))
                        .foregroundStyle(FDTheme.warning)
                    Text("Objectif : \(challenge.targetScore) pts")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(FDTheme.warning)
                }
            }

            Spacer(minLength: 4)

            if unlocked {
                Button(action: onPlay) {
                    Text("Rejouer")
                        .font(FDFont.body(11, black: true))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Capsule().fill(FDTheme.primary))
                        .foregroundStyle(.white)
                }
                .buttonStyle(FDChoiceButtonStyle())
            } else {
                Button(action: onUnlock) {
                    HStack(spacing: 3) {
                        Image(systemName: "seal.fill").font(.system(size: 9))
                        Text("\(challenge.unlockCost)")
                    }
                    .font(FDFont.body(11, black: true))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Capsule().fill(canAfford ? FDTheme.amber.opacity(0.85) : Color.white.opacity(0.07)))
                    .foregroundStyle(canAfford ? .black : .secondary)
                }
                .buttonStyle(FDChoiceButtonStyle())
                .disabled(!canAfford)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Classement (local hall of fame)
//
// There is no account and no server, so this ranks every career finished on this device
// against each other. Ordering comes from FDGameEngine.careerRankScore, which weighs
// honours above raw output: Ballon d'Or, then international titles, then league and cup
// silverware, then caps and goals.

struct FDClassementView: View {
    @ObservedObject var engine: FDGameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if engine.leaderboard.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.number")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Aucune carrière classée pour l'instant.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Termine une carrière pour entrer au classement.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            VStack(spacing: 0) {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(FDTheme.primary)
                                    Text("COMMENT C'EST CLASSÉ")
                                        .font(FDFont.body(11, black: true))
                                        .foregroundStyle(FDTheme.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(FDTheme.primary.opacity(0.07))
                                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                                Text("Les 100 meilleures carrières terminées sur cet appareil. Le Ballon d'Or pèse le plus lourd, puis les titres internationaux, les titres de champion et de coupe, puis les sélections et les buts.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(14)
                            }
                            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                            .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                            VStack(spacing: 0) {
                                ForEach(Array(engine.leaderboard.enumerated()), id: \.offset) { idx, p in
                                    NavigationLink {
                                        ScrollView {
                                            FDCareerSummaryCard(player: p).padding()
                                        }
                                        .background(FDTheme.bg)
                                        .navigationTitle("\(p.firstName) \(p.lastName)")
                                        .navigationBarTitleDisplayMode(.inline)
                                    } label: {
                                        FDClassementRow(player: p, rank: idx + 1, score: engine.careerRankScore(p))
                                    }
                                    .buttonStyle(FDRowButtonStyle())
                                    if idx < engine.leaderboard.count - 1 {
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
                }
            }
            .background(FDTheme.bg)
            .navigationTitle("Classement")
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

private struct FDClassementRow: View {
    let player: FDPlayer
    let rank: Int
    let score: Int

    private var medalColor: Color {
        switch rank {
        case 1: return FDTheme.amber
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return FDTheme.primary
        }
    }

    private var displayName: String {
        player.alias.isEmpty ? "\(player.firstName) \(player.lastName)" : player.alias
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(medalColor.opacity(rank <= 3 ? 0.22 : 0.12))
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(FDFont.mono(rank >= 100 ? 11 : 13, bold: true))
                    .foregroundStyle(medalColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(displayName)
                        .font(FDFont.body(14, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                        .lineLimit(1)
                    if !player.alias.isEmpty {
                        Text("\(player.firstName) \(player.lastName)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Text("\(fdFlag(for: player.nationality)) \(player.position.rawValue) · \(player.club.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    let ballons = player.awardCounts[FDAward.ballonDor.rawValue] ?? 0
                    if ballons > 0 { FDMiniStat(value: "\(ballons)", label: "B. d'Or", color: FDTheme.amber) }
                    if player.leagueTitles > 0 { FDMiniStat(value: "\(player.leagueTitles)", label: "titres", color: FDTheme.amber) }
                    if player.cupTitles > 0 { FDMiniStat(value: "\(player.cupTitles)", label: "coupes", color: FDTheme.accentTeal) }
                    FDMiniStat(value: "\(player.careerGoals)", label: "buts", color: FDTheme.success)
                    FDMiniStat(value: "\(player.nationalCaps)", label: "sél.", color: FDTheme.primary)
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(score)")
                    .font(FDFont.mono(14, bold: true))
                    .foregroundStyle(medalColor)
                Text("PTS")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Alias prompt shown once a career is over

struct FDAliasPromptCard: View {
    @ObservedObject var engine: FDGameEngine
    @State private var alias = ""
    @State private var saved = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FDTheme.amber)
                Text("ENTRER AU CLASSEMENT")
                    .font(FDFont.body(11, black: true))
                    .foregroundStyle(FDTheme.amber)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(FDTheme.amber.opacity(0.08))
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            if saved {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FDTheme.success)
                    Text("Carrière signée « \(alias) ».")
                        .font(FDFont.body(13))
                        .foregroundStyle(FDTheme.textPrimary)
                    Spacer()
                }
                .padding(14)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choisis un pseudo pour signer cette carrière au classement. Tu peux aussi laisser le nom du joueur.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Ton pseudo", text: $alias)
                        .font(FDFont.body(15))
                        .foregroundStyle(FDTheme.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: FDTheme.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: FDTheme.radiusMD)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )

                    Button {
                        FDHaptics.success()
                        engine.setAliasForLatestCareer(alias)
                        withAnimation(.fdSoft) { saved = true }
                    } label: {
                        Text("Signer ma carrière")
                    }
                    .buttonStyle(FDPrimaryButtonStyle())
                    .disabled(alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(14)
            }
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(FDTheme.amber.opacity(0.22), lineWidth: 1))
    }
}
