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
                            .font(.body)
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
                                        .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                                VStack(spacing: 2) {
                                    Text("\(totalGoals)")
                                        .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.success)
                                    Text("BUTS TOTAUX")
                                        .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                                VStack(spacing: 2) {
                                    Text("\(totalApps)")
                                        .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.primary)
                                    Text("MATCHS TOTAUX")
                                        .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
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
                        .fdCardSurface()
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
                    .font(FDFont.mono(15, bold: true))
                    .foregroundStyle(FDTheme.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(player.firstName) \(player.lastName)")
                    .font(FDFont.body(16, black: true))
                    .foregroundStyle(FDTheme.textPrimary)
                Text("\(fdFlag(for: player.nationality)) \(player.position.rawValue) · retraité à \(player.age) ans")
                    .font(.footnote)
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
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
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
                .font(FDFont.mono(14, bold: true))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
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
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        Text("Achetée à l'unité, une compétence ne vaut que pour une seule carrière. Pour la garder définitivement, compte cinq fois le prix. Tu n'en emportes que \(FDMaxEquippedCompetences) par carrière — à toi de choisir lesquelles au moment de la créer.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(14)
                    }
                    .fdCardSurface()
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
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(band.color)
                                    Text(band.title.uppercased())
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundStyle(band.color)
                                    Spacer()
                                    Text(band.subtitle)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(band.color.opacity(0.08))
                                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                            }

                            FDSkillRow(
                                skill: skill,
                                coins: engine.legendCoins,
                                owned: engine.ownedCompetenceIDs.contains(skill.id),
                                charges: engine.competenceCharges[skill.id] ?? 0,
                                onBuyCharge: { engine.purchaseCompetenceCharge(skill.id) },
                                onBuyPermanent: { engine.purchaseCompetencePermanently(skill.id) }
                            )
                            if idx < engine.permanentSkills.count - 1 {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .fdCardSurface()
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
    let coins: Int
    let owned: Bool
    /// Unused single-career charges already in stock, if any.
    let charges: Int
    let onBuyCharge: () -> Void
    let onBuyPermanent: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(owned ? FDTheme.amber.opacity(0.15) : FDTheme.primary.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: owned ? "checkmark.seal.fill" : skill.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(owned ? FDTheme.amber : FDTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(skill.name)
                        .font(FDFont.body(15, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                    if owned {
                        Text("ACQUISE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(FDTheme.amber)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(FDTheme.amber.opacity(0.16), in: Capsule())
                    } else if charges > 0 {
                        Text("×\(charges)")
                            .font(FDFont.mono(12, bold: true))
                            .foregroundStyle(FDTheme.success)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(FDTheme.success.opacity(0.16), in: Capsule())
                    }
                }
                Text(skill.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !owned {
                    // Two ways to buy: one career at the base price, or outright at five
                    // times that. Owning it outright stops it costing a charge every run.
                    HStack(spacing: 6) {
                        FDBuyButton(
                            label: "1 carrière",
                            cost: skill.cost,
                            enabled: coins >= skill.cost,
                            tint: FDTheme.primary,
                            action: onBuyCharge
                        )
                        FDBuyButton(
                            label: "Définitif",
                            cost: skill.permanentCost,
                            enabled: coins >= skill.permanentCost,
                            tint: FDTheme.amber,
                            action: onBuyPermanent
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
    }
}

private struct FDBuyButton: View {
    let label: String
    let cost: Int
    let enabled: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                Image(systemName: "seal.fill").font(.system(size: 11))
                Text("\(cost)")
                    .font(FDFont.mono(12, bold: true))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(enabled ? tint.opacity(0.9) : Color.white.opacity(0.07)))
            .foregroundStyle(enabled ? (tint == FDTheme.amber ? .black : .white) : Color.secondary)
        }
        .buttonStyle(FDChoiceButtonStyle())
        .disabled(!enabled)
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
                                    .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                            VStack(spacing: 2) {
                                Text("\(unlocked)")
                                    .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.warning)
                                Text("DÉBLOQUÉS")
                                    .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                            VStack(spacing: 2) {
                                Text("\(conquered)")
                                    .font(FDFont.mono(22, bold: true)).foregroundStyle(FDTheme.amber)
                                Text("CONQUIS")
                                    .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
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
                    .fdCardSurface()

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
                                        .font(.system(size: 12, weight: .bold)).foregroundStyle(band.color)
                                    Text(band.title.uppercased())
                                        .font(.system(size: 12, weight: .black)).foregroundStyle(band.color)
                                    Text(band.subtitle)
                                        .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(done)/\(items.count)")
                                        .font(FDFont.mono(12, bold: true))
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
                    .fdCardSurface()
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
                RoundedRectangle(cornerRadius: 7)
                    .fill(conquered ? FDTheme.amber.opacity(0.15) : FDTheme.primary.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: conquered ? "trophy.fill" : "person.fill.questionmark")
                    .font(.system(size: 14))
                    .foregroundStyle(conquered ? FDTheme.amber : FDTheme.primary)
            }

            // Name + meta on one line, archetype underneath, objective folded into the
            // meta line — three lines instead of four, and no line left half empty.
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(challenge.name)
                        .font(FDFont.body(14, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                        .lineLimit(1)
                    if conquered {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(FDTheme.amber)
                    }
                }

                HStack(spacing: 4) {
                    Text("\(fdFlag(for: challenge.nationality)) \(challenge.era) · \(challenge.position.rawValue)")
                        .foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.secondary.opacity(0.5))
                    Text("\(challenge.targetScore) pts")
                        .foregroundStyle(FDTheme.warning)
                }
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

                Text(challenge.archetype)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.75))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            if unlocked {
                Button(action: onPlay) {
                    Text("Rejouer")
                        .font(FDFont.body(14, black: true))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Capsule().fill(FDTheme.primary))
                        .foregroundStyle(.white)
                }
                .buttonStyle(FDChoiceButtonStyle())
            } else {
                Button(action: onUnlock) {
                    HStack(spacing: 3) {
                        Image(systemName: "seal.fill").font(.system(size: 12))
                        Text("\(challenge.unlockCost)")
                    }
                    .font(FDFont.body(14, black: true))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Capsule().fill(canAfford ? FDTheme.amber.opacity(0.85) : Color.white.opacity(0.07)))
                    .foregroundStyle(canAfford ? .black : .secondary)
                }
                .buttonStyle(FDChoiceButtonStyle())
                .disabled(!canAfford)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
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
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Termine une carrière pour entrer au classement.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            VStack(spacing: 0) {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.footnote.weight(.bold))
                                        .foregroundStyle(FDTheme.primary)
                                    Text("COMMENT C'EST CLASSÉ")
                                        .font(FDFont.body(14, black: true))
                                        .foregroundStyle(FDTheme.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(FDTheme.primary.opacity(0.07))
                                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                                Text("Les 100 meilleures carrières terminées sur cet appareil. Le Ballon d'Or pèse le plus lourd, puis les titres internationaux, les titres de champion et de coupe, puis les sélections et les buts.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(14)
                            }
                            .fdCardSurface()

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
                            .fdCardSurface()
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: rank <= 3
                                ? [medalColor.opacity(0.38), medalColor.opacity(0.14)]
                                : [medalColor.opacity(0.14), medalColor.opacity(0.07)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(FDFont.mono(rank >= 100 ? 11 : 13, bold: true))
                    .foregroundStyle(medalColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(displayName)
                        .font(FDFont.body(16, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                        .lineLimit(1)
                    if !player.alias.isEmpty {
                        Text("\(player.firstName) \(player.lastName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Text("\(fdFlag(for: player.nationality)) \(player.position.rawValue) · \(player.club.name)")
                    .font(.footnote)
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
                    .font(FDFont.mono(16, bold: true))
                    .foregroundStyle(medalColor)
                Text("PTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
    }
}

// MARK: - Alias prompt shown once a career is over

struct FDAliasPromptCard: View {
    @ObservedObject var engine: FDGameEngine
    @State private var alias = ""
    @State private var saved = false

    /// Where the career that just ended landed in the local top 100, if it made it.
    private var rank: Int? {
        guard let latest = engine.archivedCareers.first else { return nil }
        let board = engine.leaderboard
        guard let idx = board.firstIndex(where: {
            $0.firstName == latest.firstName && $0.lastName == latest.lastName
                && $0.careerApps == latest.careerApps && $0.careerGoals == latest.careerGoals
        }) else { return nil }
        return idx + 1
    }

    /// What to show once signed — the chosen handle, or the player's own name when the
    /// field was left empty.
    private var signedLabel: String {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let who = trimmed.isEmpty
            ? (engine.archivedCareers.first.map { "\($0.firstName) \($0.lastName)" } ?? "cette carrière")
            : trimmed
        if let rank { return "Carrière signée « \(who) » — \(rank)e au classement." }
        return "Carrière signée « \(who) »."
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(FDTheme.amber)
                Text("ENTRER AU CLASSEMENT")
                    .font(FDFont.body(14, black: true))
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
                    Text(signedLabel)
                        .font(FDFont.body(15))
                        .foregroundStyle(FDTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(12)
            } else {
                VStack(alignment: .leading, spacing: 9) {
                    if let rank {
                        HStack(spacing: 6) {
                            Image(systemName: rank <= 3 ? "medal.fill" : "list.number")
                                .font(.system(size: 14, weight: .bold))
                            Text(rank == 1
                                 ? "Meilleure carrière de ton classement !"
                                 : "\(rank)e au classement de tes carrières.")
                                .font(FDFont.body(14, black: true))
                        }
                        .foregroundStyle(FDTheme.amber)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(FDTheme.amber.opacity(0.14), in: Capsule())
                    }

                    Text("Choisis un pseudo pour signer cette carrière au classement. Tu peux aussi laisser le nom du joueur.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Ton pseudo", text: $alias)
                        .font(FDFont.body(17))
                        .foregroundStyle(FDTheme.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: FDTheme.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: FDTheme.radiusMD)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )

                    Button {
                        FDHaptics.success()
                        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { engine.setAliasForLatestCareer(trimmed) }
                        withAnimation(.fdSoft) { saved = true }
                    } label: {
                        Text(alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                             ? "Valider avec mon nom"
                             : "Signer ma carrière")
                    }
                    .buttonStyle(FDPrimaryButtonStyle())
                }
                .padding(12)
            }
        }
        .fdCardSurface()
        .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(FDTheme.amber.opacity(0.22), lineWidth: 1))
    }
}
