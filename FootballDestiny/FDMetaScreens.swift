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
                                        .font(FDFont.mono(23, bold: true)).foregroundStyle(FDTheme.amber)
                                    Text("CARRIÈRES")
                                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                                VStack(spacing: 2) {
                                    Text("\(totalGoals)")
                                        .font(FDFont.mono(23, bold: true)).foregroundStyle(FDTheme.success)
                                    Text("BUTS TOTAUX")
                                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                                VStack(spacing: 2) {
                                    Text("\(totalApps)")
                                        .font(FDFont.mono(23, bold: true)).foregroundStyle(FDTheme.primary)
                                    Text("MATCHS TOTAUX")
                                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
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
                    .font(FDFont.mono(17, bold: true))
                    .foregroundStyle(FDTheme.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(player.firstName) \(player.lastName)")
                    .font(FDFont.body(18, black: true))
                    .foregroundStyle(FDTheme.textPrimary)
                Text("\(fdFlag(for: player.nationality)) \(player.position.rawValue) · retraité à \(player.age) ans")
                    .font(.subheadline)
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
                .font(.subheadline.weight(.bold))
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
                .font(FDFont.mono(16, bold: true))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .bold))
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
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundStyle(FDTheme.amber)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(engine.legendCoins) pièces")
                                    .font(FDFont.display(21))
                                    .foregroundStyle(FDTheme.amber)
                                Text("Solde disponible")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        Text("Achetée à l'unité, une compétence ne vaut que pour une seule carrière. Pour la garder définitivement, compte cinq fois le prix. Tu n'en emportes que \(FDMaxEquippedCompetences) par carrière — à toi de choisir lesquelles au moment de la créer.")
                            .font(.subheadline)
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
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(band.color)
                                    Text(band.title.uppercased())
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundStyle(band.color)
                                    Spacer()
                                    Text(band.subtitle)
                                        .font(.system(size: 13, weight: .bold))
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
                    .font(.system(size: 17))
                    .foregroundStyle(owned ? FDTheme.amber : FDTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(skill.name)
                        .font(FDFont.body(17, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                    if owned {
                        Text("ACQUISE")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(FDTheme.amber)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(FDTheme.amber.opacity(0.16), in: Capsule())
                    } else if charges > 0 {
                        Text("×\(charges)")
                            .font(FDFont.mono(14, bold: true))
                            .foregroundStyle(FDTheme.success)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(FDTheme.success.opacity(0.16), in: Capsule())
                    }
                }
                Text(skill.description)
                    .font(.system(size: 15))
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
                    .font(.system(size: 14, weight: .bold))
                Image(systemName: "seal.fill").font(.system(size: 13))
                Text("\(cost)")
                    .font(FDFont.mono(14, bold: true))
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
                                    .font(FDFont.mono(23, bold: true)).foregroundStyle(FDTheme.primary)
                                Text("TOTAL")
                                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                            VStack(spacing: 2) {
                                Text("\(unlocked)")
                                    .font(FDFont.mono(23, bold: true)).foregroundStyle(FDTheme.warning)
                                Text("DÉBLOQUÉS")
                                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                            VStack(spacing: 2) {
                                Text("\(conquered)")
                                    .font(FDFont.mono(23, bold: true)).foregroundStyle(FDTheme.amber)
                                Text("CONQUIS")
                                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
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
                                        .font(.system(size: 14, weight: .bold)).foregroundStyle(band.color)
                                    Text(band.title.uppercased())
                                        .font(.system(size: 14, weight: .black)).foregroundStyle(band.color)
                                    Text(band.subtitle)
                                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(done)/\(items.count)")
                                        .font(FDFont.mono(14, bold: true))
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
                    .font(.system(size: 16))
                    .foregroundStyle(conquered ? FDTheme.amber : FDTheme.primary)
            }

            // Name + meta on one line, archetype underneath, objective folded into the
            // meta line — three lines instead of four, and no line left half empty.
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(challenge.name)
                        .font(FDFont.body(16, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                        .lineLimit(1)
                    if conquered {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
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
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

                Text(challenge.archetype)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary.opacity(0.75))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            if unlocked {
                Button(action: onPlay) {
                    Text("Rejouer")
                        .font(FDFont.body(16, black: true))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Capsule().fill(FDTheme.primary))
                        .foregroundStyle(.white)
                }
                .buttonStyle(FDChoiceButtonStyle())
            } else {
                Button(action: onUnlock) {
                    HStack(spacing: 3) {
                        Image(systemName: "seal.fill").font(.system(size: 14))
                        Text("\(challenge.unlockCost)")
                    }
                    .font(FDFont.body(16, black: true))
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
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            VStack(spacing: 0) {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(FDTheme.primary)
                                    Text("COMMENT C'EST CLASSÉ")
                                        .font(FDFont.body(16, black: true))
                                        .foregroundStyle(FDTheme.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(FDTheme.primary.opacity(0.07))
                                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Les 100 meilleures carrières terminées sur cet appareil. Le Ballon d'Or pèse le plus lourd, puis les titres internationaux, les titres de champion et de coupe, puis les sélections et les buts.")
                                    Text("L'argent n'ajoute aucun point : il sert uniquement à départager deux carrières à égalité de score, par paliers de patrimoine.")
                                }
                                .font(.subheadline)
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
                        .font(FDFont.body(18, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                        .lineLimit(1)
                    // Only the signature shows in the table: the real name belongs to the
                    // career sheet, one tap away.
                }
                Text("\(fdFlag(for: player.nationality)) \(player.position.rawValue) · \(player.club.name)")
                    .font(.subheadline)
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
                    .font(FDFont.mono(18, bold: true))
                    .foregroundStyle(medalColor)
                Text("PTS")
                    .font(.system(size: 12, weight: .bold))
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
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(FDTheme.amber)
                Text("ENTRER AU CLASSEMENT")
                    .font(FDFont.body(16, black: true))
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
                        .font(FDFont.body(17))
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
                                .font(.system(size: 16, weight: .bold))
                            Text(rank == 1
                                 ? "Meilleure carrière de ton classement !"
                                 : "\(rank)e au classement de tes carrières.")
                                .font(FDFont.body(16, black: true))
                        }
                        .foregroundStyle(FDTheme.amber)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(FDTheme.amber.opacity(0.14), in: Capsule())
                    }

                    Text("Choisis un pseudo pour signer cette carrière au classement. Tu peux aussi laisser le nom du joueur.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Ton pseudo", text: $alias)
                        .font(FDFont.body(19))
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

// MARK: - Règles

private enum FDRegleTab: String, CaseIterable, Identifiable {
    case jeu = "Jeu"
    case monnaies = "Monnaies"
    case boutique = "Boutique"
    case classement = "Classement"
    var id: String { rawValue }
}

/// Explains every system in the game. Split across four tabs rather than one long scroll:
/// each tab answers a single question, and the numbers matter more than the prose, so the
/// explanations stay to one sentence and the barèmes are laid out as rows.
struct FDReglesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tab: FDRegleTab = .jeu

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(FDRegleTab.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                ScrollView {
                    VStack(spacing: 12) {
                        switch tab {
                        case .jeu: jeuTab
                        case .monnaies: monnaiesTab
                        case .boutique: boutiqueTab
                        case .classement: classementTab
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 20)
                    .fdAppear()
                    .id(tab)
                }
            }
            .background(FDTheme.bg)
            .navigationTitle("Règles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                        .tint(FDTheme.primary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Onglet Jeu

    private var jeuTab: some View {
        Group {
            rulesCard(icon: "book.fill", title: "Le principe", color: FDTheme.primary) {
                paragraph("Une carrière narrative : tu ne diriges pas les matchs, tu prends les décisions qui font une vie de footballeur.")
                paragraph("Les conséquences d'un choix ne sont jamais annoncées avant : elles se découvrent une fois décidé.")
            }
            rulesCard(icon: "figure.soccer", title: "Une carrière", color: FDTheme.accentTeal) {
                bullet("Identité, ville de naissance et pied fort tirés au sort, cohérents avec la nationalité.")
                bullet("Quatre postes : gardien, défenseur, milieu, attaquant. Le poste pondère tes stats et les scènes.")
                bullet("Chaque saison alterne scènes à choix, matchs simulés et bilan.")
                bullet("Une saison s'arrête sur une à trois scènes ordinaires, selon ce qu'elle vaut. Et chaque rendez-vous — grand match, étape d'un défi — en retire une : une saison pleine de moments forts ne s'allonge pas de scènes en plus.")
                bullet("Un grand rendez-vous se joue vraiment : après ton choix, le match a lieu et le lendemain arrive sous forme d'article — le score, ce que tu y as fait, et ce que la soirée change pour toi.")
                bullet("À l'intersaison, tu n'es jamais coincé. Si le club ne compte plus sur toi, trois clubs de ton niveau se présentent ; en fin de parcours, celui où tout a commencé rappelle.")
                bullet("Retraite possible dès 30 ans, ou imposée par l'âge.")
                bullet("À la retraite : historique, points, pièces, et signature pour entrer au classement.")
            }
            rulesCard(icon: "sportscourt.fill", title: "Le grand rendez-vous", color: FDTheme.amber) {
                paragraph("Chaque saison s'arrête une fois sur un match qui compte plus que les autres, dans son dernier quart. Le thème dépend d'où en est ta carrière :")
                ruleRow("Championnat, titre, maintien", "20 à 55 %")
                ruleRow("Finale de coupe nationale", "18 à 30 %")
                ruleRow("Soirée européenne", "0 à 30 %")
                ruleRow("Sélection nationale", "0 à 26 %")
                ruleRow("Derby", "6 à 15 %")
                bullet("Renvoyé en réserve, tu joues des barrages ; réputation au-dessus de 75, tu joues des finales européennes et des tournois internationaux.")
            }
            rulesCard(icon: "arrow.triangle.2.circlepath", title: "L'intersaison", color: FDTheme.accentTeal) {
                paragraph("Entre deux saisons, un club peut se manifester. Le transfert ne se fait plus tout seul : tu lis l'offre et tu décides.")
                bullet("Partir à l'étranger coûte les tiens et les tribunes, et rapporte de la réputation.")
                bullet("Rester te rend les supporters et le président, et fait retomber ta cote.")
                bullet("Sans aucune offre, l'intersaison se joue avec ton propre club : prolonger, exiger, ou attendre.")
            }
            rulesCard(icon: "figure.walk.motion", title: "Le fil d'une légende", color: FDTheme.amber) {
                paragraph("Chaque défi Gloire du Passé a son propre chemin : les clubs qu'elle a choisis, les transferts qu'elle a faits, la finale continentale et le tournoi qui l'ont installée — et le geste précis qui l'a rendue légendaire, le but, l'arrêt ou le carton.")
                paragraph("Ces moments arrivent à l'âge exact où elle les a vécus. À chaque fois, deux routes : refaire son choix, ou écrire le tien.")
                bullet("Les transferts du fil changent réellement de club : le nom du club apparaît sur le bouton, et signer t'y emmène pour de bon, avec la ligne dans ton parcours et la prime à la signature.")
                bullet("Suivre sa route donne ce qu'elle avait — et coûte ce qu'elle a payé.")
                bullet("S'en écarter te rend ta propre carrière, avec ce que ça vaut et ce que ça retire.")
                ruleRow("Légendes", "50")
                ruleRow("Moments par légende", "6")
                ruleRow("Moments écrits en tout", "300")
            }
            rulesCard(icon: "crown.fill", title: "Le talent", color: FDTheme.amber) {
                paragraph("Toute carrière démarre avec \(FDPotentialShop.freeStars) étoiles de potentiel acquises, même sans un seul point en banque : elles s'affichent pleines dès l'ouverture de la fiche. Les points ne remplissent que les \(FDPotentialShop.buyableStars) suivantes, et seulement pour la carrière que tu lances ensuite.")
                paragraph("Le total d'étoiles décide aussi de là où tu démarres : à 2 étoiles, la deuxième division en moyenne, avec un club au-dessus — plus dur — et deux en dessous où tu joueras tout de suite.")
                paragraph("Un palier de talent est tiré au lancement, et jamais annoncé : deux carrières lancées avec les mêmes étoiles ne valent pas la même chose. Il se révèle de lui-même après deux saisons.")
                ruleRow("Ordinaire", "46 %")
                ruleRow("Prometteur", "27 %")
                ruleRow("Tardif", "18 %")
                ruleRow("Pépite", "7 %")
                ruleRow("Génération", "2 %")
                bullet("Le palier joue sur le plafond et sur la vitesse de progression : une pépite gagne jusqu'à 4 points par attribut et par saison, un joueur tardif 2.")
                bullet("Les étoiles achetées ne garantissent rien : elles vident le palier tardif et poussent les paliers hauts. Une carrière peut exploser sans une seule étoile — rarement.")
            }
            rulesCard(icon: "arrow.up.arrow.down", title: "Pro, et rien d'autre", color: FDTheme.primary) {
                paragraph("La carrière commence et se termine chez les professionnels : il n'y a pas de catégorie de jeunes à traverser.")
                bullet("Deux mauvais signaux cumulés sur une saison — trop peu de matchs, note trop basse, coach perdu — et tu es rétrogradé en réserve.")
                bullet("On en remonte : une bonne saison de réserve, ou un coach reconquis, et le groupe pro te rappelle.")
            }
            rulesCard(icon: "externaldrive.fill", title: "Sauvegarde", color: FDTheme.textMuted) {
                bullet("Aucun compte : tout est stocké sur l'appareil.")
                bullet("Une carrière en cours à la fois.")
                bullet("Points, pièces, compétences et classement survivent aux carrières.")
            }
        }
    }

    // MARK: Onglet Monnaies

    private var monnaiesTab: some View {
        Group {
            rulesCard(icon: "star.circle.fill", title: "Points de carrière", color: FDTheme.warning) {
                paragraph("Gagnés à chaque retraite, quelle qu'elle soit. Ils n'achètent qu'une chose : des étoiles de potentiel, et uniquement pour la carrière suivante — jamais pour celle en cours.")
                ruleRow("2 étoiles de départ", "offertes")
                ruleRow("3e étoile", "\(FDPotentialShop.costOfStar(1)) pts")
                ruleRow("4e étoile", "\(FDPotentialShop.costOfStar(2)) pts")
                ruleRow("5 étoiles (total)", "\(FDPotentialShop.cumulativeCost(for: FDPotentialShop.buyableStars)) pts")
                ruleRow("Par étoile", "+5 % de potentiel")
            }
            rulesCard(icon: "seal.fill", title: "Pièces", color: FDTheme.blueGlow) {
                paragraph("Bien plus rares : elles ne récompensent que la qualité d'une carrière, de 1 à 14 pièces.")
                ruleRow("Terminer une carrière", "+1")
                ruleRow("Ballon d'Or", "+2 (max 4)")
                ruleRow("Titre international", "+2 (max 3)")
                ruleRow("Soulier d'Or", "+1 (max 2)")
                ruleRow("Championnat", "+1 (max 2)")
                ruleRow("Coupe", "+1 (max 2)")
                ruleRow("100 puis 200 buts", "+1 chacun")
                ruleRow("Réputation 70 puis 88", "+1 chacun")
                ruleRow("50 sélections", "+1")
            }
        }
    }

    // MARK: Onglet Boutique & Défis

    private var boutiqueTab: some View {
        Group {
            rulesCard(icon: "cart.fill", title: "Boutique", color: FDTheme.blueGlow) {
                paragraph("Payée en pièces. Chaque compétence s'achète de deux façons :")
                ruleRow("Usage unique", "prix affiché")
                ruleRow("Définitive", "×5 le prix")
                bullet("L'usage unique est consommé au lancement de la carrière où tu l'équipes.")
                bullet("La définitive reste disponible dans toutes tes carrières.")
                bullet("\(FDMaxEquippedCompetences) compétences équipées au maximum par carrière — au-delà, c'est trop facile.")
            }
            rulesCard(icon: "trophy.fill", title: "Défi Gloire du Passé", color: FDTheme.amber) {
                paragraph("\(FDLegendChallenges.count) légendes à égaler. Chacune se débloque avec des pièces puis impose son cadre : nationalité, poste, style et personnalité.")
                paragraph("Réussi si le score de la carrière atteint la cible. Une légende conquise le reste définitivement.")
                ForEach(FDMetaTierInfo.all, id: \.tier) { tier in
                    ruleRow("Palier \(tier.tier) · \(tier.title)", tier.subtitle.capitalized)
                }
            }
        }
    }

    // MARK: Onglet Classement

    private var classementTab: some View {
        Group {
            rulesCard(icon: "list.number", title: "Le barème", color: FDTheme.destructive) {
                paragraph("Les 100 meilleures carrières terminées, classées par un score unique.")
                ruleRow("Ballon d'Or", "600 pts")
                ruleRow("Titre international", "400 pts")
                ruleRow("Soulier d'Or", "150 pts")
                ruleRow("Coupe / Europe", "130 pts")
                ruleRow("Championnat", "110 pts")
                ruleRow("Révélation", "40 pts")
                ruleRow("Sélection", "3 pts")
                ruleRow("Saison jouée", "10 pts")
                ruleRow("Réputation finale", "1 pt / point")
            }
            rulesCard(icon: "figure.soccer", title: "Selon le poste", color: FDTheme.primary) {
                paragraph("Le même exploit ne vaut pas la même chose partout.")
                ruleRow("Attaquant", "buts ×3, passes ×1, note")
                ruleRow("Milieu", "passes ×3, buts ×1, note ×2")
                ruleRow("Défenseur", "note ×3, matchs ÷2, buts ×2")
                ruleRow("Gardien", "note ×3, matchs ÷2")
            }
            rulesCard(icon: "eurosign.circle.fill", title: "Départage : le patrimoine", color: FDTheme.success) {
                paragraph("L'argent n'ajoute aucun point. Il départage seulement deux carrières à égalité de score : d'abord le palier, puis la fortune exacte.")
                ForEach(Array(FDWealthScale.rows.enumerated()), id: \.offset) { index, row in
                    ruleRow(row.label, "palier \(index + 1)")
                }
            }
        }
    }

    // MARK: Blocs de construction

    @ViewBuilder
    private func rulesCard<Content: View>(icon: String, title: String, color: Color,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
                Text(title.uppercased())
                    .font(FDFont.body(16, black: true))
                    .foregroundStyle(color)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(FDTheme.headerWash(color))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            VStack(alignment: .leading, spacing: 7) {
                content()
            }
            .padding(12)
        }
        .fdCardSurface()
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(FDTheme.textPrimary.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Circle()
                .fill(FDTheme.primary.opacity(0.7))
                .frame(width: 5, height: 5)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(FDTheme.textPrimary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func ruleRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 6)
            Text(value)
                .font(FDFont.mono(15, bold: true))
                .foregroundStyle(FDTheme.textPrimary)
                .lineLimit(1)
        }
    }
}
