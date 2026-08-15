import SwiftUI
import UIKit
import Foundation

struct FDGameShellView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FDCarriereTab(engine: engine, screen: $screen)
                .tabItem { Label("Carrière", systemImage: "star.fill") }
                .tag(0)
            FDJournalTab(engine: engine)
                .tabItem { Label("Journal", systemImage: "newspaper.fill") }
                .tag(1)
            FDOptionsTab(engine: engine, screen: $screen)
                .tabItem { Label("Options", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(FDTheme.primary)
        .safeAreaInset(edge: .top, spacing: 0) {
            FDStatusHeader(engine: engine)
        }
        .overlay(alignment: .top) {
            if let toast = engine.toast {
                FDToastView(text: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: engine.toast)
    }
}

// MARK: - Status Header

struct FDStatusHeader: View {
    @ObservedObject var engine: FDGameEngine

    var body: some View {
        if let p = engine.player {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    FDLogoBadge(size: 24, corner: 6)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(p.firstName) \(p.lastName)")
                            .font(FDFont.body(13, black: true))
                        Text("\(fdFlag(for: p.club.country)) \(p.club.name)  ·  \(p.position.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "eurosign.circle.fill")
                                .foregroundStyle(FDTheme.amber)
                            Text(fdFormatMoney(p.money))
                                .foregroundStyle(FDTheme.amber)
                        }
                        .font(FDFont.mono(11, bold: true))
                        HStack(spacing: 3) {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundStyle(FDTheme.primary)
                            Text("\(p.cond.forme)%")
                                .foregroundStyle(FDTheme.primary)
                        }
                        .font(FDFont.mono(11, bold: true))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Season progress
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.07))
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [FDTheme.primary, FDTheme.accentTeal],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * CGFloat(p.calendar.week) / CGFloat(max(p.calendar.seasonWeeks, 1)))
                            .animation(.fdSoft, value: p.calendar.week)
                    }
                }
                .frame(height: 2)

                HStack {
                    Text("\(fdSeasonLabel(p.calendar.season))  ·  \(p.age) ans  ·  Sem. \(p.calendar.week)/\(p.calendar.seasonWeeks)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill").font(.system(size: 8))
                        Text("Rép. \(p.cond.reputation)")
                    }
                    .foregroundStyle(FDTheme.amber)
                }
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
            }
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) {
                Rectangle().fill(FDTheme.primary.opacity(0.12)).frame(height: 1)
            }
        }
    }
}

struct FDToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(FDTheme.gold.opacity(0.4), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 8)
            .padding(.horizontal, 24)
    }
}

// MARK: - Shared Design Components (FCSManager-style)

/// Section header with colored icon + UPPERCASE label — mirrors FCSManager's section rows
private struct FDSectionHeader: View {
    let icon: String
    let title: String
    var badge: String? = nil
    var color: Color = FDTheme.amber

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(FDFont.body(11, black: true))
                .foregroundStyle(color)
            Spacer()
            if let b = badge {
                Text(b)
                    .font(FDFont.mono(10, bold: true))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: FDTheme.radiusMD))
    }
}

/// 4-column statistics grid — matches FCSManager's Trophées/Championships/European Titles/Best Finish grid
private struct FDStatsGrid: View {
    struct Cell: Identifiable {
        let id = UUID()
        let value: String
        let label: String
        let icon: String
        var color: Color = FDTheme.amber
    }
    let cells: [Cell]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { idx, cell in
                VStack(spacing: 3) {
                    Image(systemName: cell.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(cell.color)
                    Text(cell.value)
                        .font(FDFont.mono(20, bold: true))
                        .foregroundStyle(.white)
                    Text(cell.label.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                if idx < cells.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 44)
                }
            }
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

/// Compact attribute bar row — FCSManager style with thin progress bar
private struct FDAttrBar: View {
    let label: String
    let value: Int
    var max: Int = 100
    var color: Color = FDTheme.primary

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 4)
                    Capsule()
                        .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(value) / CGFloat(max), height: 4)
                        .animation(.fdSoft, value: value)
                }
            }
            .frame(height: 4)
            Text("\(value)")
                .font(FDFont.mono(11, bold: true))
                .foregroundStyle(value >= 80 ? FDTheme.success : value >= 60 ? FDTheme.primary : .secondary)
                .frame(width: 26, alignment: .trailing)
        }
    }
}

/// Compact condition pill — inline in a row
private struct FDCondPill: View {
    let label: String
    let value: Int
    var color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(FDFont.mono(16, bold: true))
                .foregroundStyle(color)
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Scene helpers (unchanged)

private func fdAttrCategoryColor(_ cat: FDAttrCategory) -> Color {
    switch cat {
    case .tech: return FDTheme.accentTeal
    case .phys: return FDTheme.primary
    case .ment: return FDTheme.amber
    case .def: return .blue
    }
}

private func fdAttrCategoryIcon(_ cat: FDAttrCategory) -> String {
    switch cat {
    case .tech: return "hand.raised.fill"
    case .phys: return "figure.run"
    case .ment: return "brain.fill"
    case .def: return "shield.fill"
    }
}

private func fdSceneSymbol(_ category: String) -> String {
    switch category {
    case "Académie": return "graduationcap.fill"
    case "Famille": return "person.2.fill"
    case "Essais": return "magnifyingglass"
    case "Vestiaire": return "figure.socialdance"
    case "Entraînement": return "figure.run"
    case "Presse": return "mic.fill"
    case "Blessure": return "bandage.fill"
    case "Agent": return "person.crop.circle.badge.checkmark"
    case "Sponsor": return "briefcase.fill"
    case "Contrat": return "doc.text.fill"
    case "Couple": return "heart.fill"
    case "Logement": return "house.fill"
    case "Argent": return "eurosign.circle.fill"
    case "Crise": return "bolt.fill"
    case "Sélection": return "globe.europe.africa.fill"
    case "Transfert": return "arrow.triangle.2.circlepath"
    case "Trophée": return "trophy.fill"
    case "Retraite": return "sunset.fill"
    case "Moment décisif": return "scope"
    case "Rivalité": return "flame.fill"
    case "Identité de jeu": return "person.crop.circle.fill.badge.checkmark"
    case "Hygiène de vie": return "moon.zzz.fill"
    case "Préparation": return "chart.bar.fill"
    case "Supporters": return "megaphone.fill"
    default: return "calendar"
    }
}

private func fdSceneColor(_ category: String) -> Color {
    switch category {
    case "Crise", "Blessure": return .red
    case "Argent", "Sponsor": return .orange
    case "Presse": return .purple
    case "Sélection", "Transfert": return .pink
    case "Trophée": return FDTheme.amber
    case "Moment décisif": return FDTheme.primary
    case "Rivalité": return .red
    case "Identité de jeu": return FDTheme.primary
    case "Hygiène de vie": return .indigo
    case "Préparation": return FDTheme.accentTeal
    case "Supporters": return FDTheme.amber
    default: return FDTheme.accentTeal
    }
}

// MARK: - Scene visual header

struct FDCardVisual: View {
    let symbol: String
    let color: Color
    let loc: String
    let char: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [color, color.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                Text(char)
                    .font(FDFont.body(15, black: true))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
}

// MARK: - Story Card

struct FDStoryCard: View {
    @ObservedObject var engine: FDGameEngine
    let scene: FDSceneDef

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(fdSceneColor(scene.category).opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: fdSceneSymbol(scene.category))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(fdSceneColor(scene.category))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.category.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(fdSceneColor(scene.category))
                    Text(scene.location)
                        .font(FDFont.body(13, black: true))
                    Text(scene.character)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(FDTheme.card.opacity(0.6))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // Narrative text
            Text(scene.text)
                .font(.subheadline)
                .foregroundStyle(FDTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // Choices
            VStack(spacing: 0) {
                ForEach(Array(scene.choices.enumerated()), id: \.offset) { idx, choice in
                    Button {
                        FDHaptics.tap()
                        engine.resolveChoice(choice, category: scene.category)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(idx + 1)")
                                .font(FDFont.mono(11, bold: true))
                                .foregroundStyle(FDTheme.primary.opacity(0.7))
                                .frame(width: 16)
                                .padding(.top, 1)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    if let tag = choice.tag {
                                        Text(tag.uppercased())
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Capsule().fill(FDTheme.accentTeal.opacity(0.18)))
                                            .foregroundStyle(FDTheme.accentTeal)
                                    } else if let trait = choice.trait {
                                        Text(trait.rawValue.uppercased())
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Capsule().fill(FDTheme.primary.opacity(0.15)))
                                            .foregroundStyle(FDTheme.primary)
                                    }
                                }
                                Text(choice.label)
                                    .font(FDFont.body(13))
                                    .foregroundStyle(FDTheme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                if !choice.hint.isEmpty {
                                    Text(choice.hint)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(FDTheme.primary.opacity(0.5))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(FDRowButtonStyle())
                    if idx < scene.choices.count - 1 {
                        Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                    }
                }
            }
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Outcome Card

struct FDOutcomeCard: View {
    @ObservedObject var engine: FDGameEngine
    let outcome: FDChoiceOutcome
    var primaryActionTitle: String? = nil
    var primaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: fdSceneSymbol(outcome.category))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(fdSceneColor(outcome.category))
                Text(outcome.category.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(fdSceneColor(outcome.category))
                Spacer()
                Text("RÉSULTAT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FDTheme.card.opacity(0.5))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            Text(outcome.narrative)
                .font(.subheadline)
                .foregroundStyle(FDTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)

            if !outcome.pills.isEmpty {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(outcome.pills, id: \.valueText) { pill in
                            HStack(spacing: 4) {
                                Image(systemName: pill.positive ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 9, weight: .bold))
                                Text(pill.label)
                                    .font(.caption2.weight(.semibold))
                                Text(pill.valueText)
                                    .font(FDFont.mono(11, bold: true))
                            }
                            .foregroundStyle(pill.positive ? FDTheme.success : FDTheme.destructive)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background((pill.positive ? FDTheme.success : FDTheme.destructive).opacity(0.12), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }

            if let title = primaryActionTitle, let action = primaryAction {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                Button(action: action) {
                    Text(title)
                }
                .buttonStyle(FDPrimaryButtonStyle())
                .padding(14)
            }
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Match Card

struct FDMatchCard: View {
    @ObservedObject var engine: FDGameEngine
    let result: FDMatchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: competition
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FDTheme.primary)
                Text("MATCH")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(FDTheme.primary)
                Spacer()
                let isWin = result.teamScore > result.oppScore
                let isDraw = result.teamScore == result.oppScore
                Text(isWin ? "V" : isDraw ? "N" : "D")
                    .font(FDFont.mono(11, bold: true))
                    .foregroundStyle(isWin ? FDTheme.success : isDraw ? FDTheme.warning : FDTheme.destructive)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background((isWin ? FDTheme.success : isDraw ? FDTheme.warning : FDTheme.destructive).opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FDTheme.card.opacity(0.5))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // Score row
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(engine.player?.club.name ?? "Ton équipe")
                        .font(FDFont.body(13, black: true))
                    Text("Niveau adverse : \(result.opponentLevel)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(result.teamScore) – \(result.oppScore)")
                    .font(FDFont.mono(26, bold: true))
                    .foregroundStyle(.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(result.minutes > 0 ? String(format: "%.1f", result.rating) : "—")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(FDTheme.accentTeal)
                    Text("Note")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)

            if result.goals > 0 {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                HStack(spacing: 6) {
                    Image(systemName: "soccerball").font(.caption).foregroundStyle(FDTheme.success)
                    Text("\(result.goals) but\(result.goals > 1 ? "s" : "") marqué\(result.goals > 1 ? "s" : "")")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FDTheme.success)
                    if result.assists > 0 {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.triangle.turn.up.right.circle").font(.caption).foregroundStyle(FDTheme.primary)
                        Text("\(result.assists) passe\(result.assists > 1 ? "s" : "") décisive\(result.assists > 1 ? "s" : "")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FDTheme.primary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            Button {
                FDHaptics.tap()
                engine.advanceWeek()
            } label: {
                HStack {
                    Spacer()
                    Text("Continuer")
                        .font(FDFont.body(14, black: true))
                    Image(systemName: "arrow.right")
                    Spacer()
                }
                .padding(.vertical, 12)
                .foregroundStyle(FDTheme.primary)
            }
            .buttonStyle(FDRowButtonStyle())
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

struct FDMatchStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(FDFont.mono(17, bold: true))
            Text(label.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Season Card

struct FDSeasonCard: View {
    @ObservedObject var engine: FDGameEngine
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FDTheme.amber)
                Text("BILAN DE SAISON")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(FDTheme.amber)
                Spacer()
                Text("Saison \(fdSeasonLabel(max(1, (engine.player?.calendar.season ?? 1) - 1)))")
                    .font(FDFont.mono(10)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(FDTheme.amber.opacity(0.08))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(lines, id: \.self) { line in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(FDTheme.success)
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(FDTheme.textPrimary)
                    }
                }
            }
            .padding(14)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            Button {
                FDHaptics.tap()
                engine.continueAfterSeason()
            } label: {
                HStack {
                    Spacer()
                    Text(engine.player?.retired == true ? "Voir le résumé" : "Nouvelle saison →")
                        .font(FDFont.body(14, black: true))
                        .foregroundStyle(FDTheme.primary)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(FDRowButtonStyle())
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(FDTheme.amber.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Tournament Card

struct FDTournamentCard: View {
    @ObservedObject var engine: FDGameEngine
    let summary: FDTournamentSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: summary.champion ? "trophy.fill" : "globe.europe.africa.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(summary.champion ? FDTheme.amber : FDTheme.accentTeal)
                VStack(alignment: .leading, spacing: 1) {
                    Text(summary.competitionName.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(summary.champion ? FDTheme.amber : FDTheme.accentTeal)
                    Text(summary.champion ? "CHAMPION" : summary.stageReached)
                        .font(FDFont.body(13, black: true))
                }
                Spacer()
                Text(String(summary.year))
                    .font(FDFont.mono(12)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background((summary.champion ? FDTheme.amber : FDTheme.accentTeal).opacity(0.08))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            Text(summary.narrative)
                .font(.subheadline)
                .foregroundStyle(FDTheme.textPrimary)
                .padding(14)

            if summary.minutesPlayed > 0 {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                HStack(spacing: 0) {
                    FDMatchStat(value: "\(summary.minutesPlayed)'", label: "Minutes")
                    FDMatchStat(value: "\(summary.goals)", label: "Buts")
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
            }

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            Button {
                FDHaptics.tap()
                engine.continueAfterTournament()
            } label: {
                HStack {
                    Spacer()
                    Text("Continuer →")
                        .font(FDFont.body(14, black: true))
                        .foregroundStyle(FDTheme.primary)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(FDRowButtonStyle())
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Career Summary Card

struct FDCareerSummaryCard: View {
    let player: FDPlayer
    var primaryActionTitle: String? = nil
    var primaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Player name header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(FDTheme.primary.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(FDTheme.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(player.firstName) \(player.lastName)")
                        .font(FDFont.display(18))
                    Text("\(fdFlag(for: player.nationality)) \(player.nationality) · \(player.position.rawValue) · retraité à \(player.age) ans")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(FDTheme.card.opacity(0.5))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // Career stats grid
            FDStatsGrid(cells: [
                .init(value: "\(player.careerGoals)", label: "Buts", icon: "soccerball"),
                .init(value: "\(player.careerApps)", label: "Matchs", icon: "calendar", color: FDTheme.primary),
                .init(value: "\(player.careerAssists)", label: "Passes D.", icon: "arrow.triangle.turn.up.right.circle", color: FDTheme.accentTeal),
                .init(value: "\(player.nationalCaps)", label: "Sélections", icon: "globe.europe.africa.fill", color: FDTheme.warning),
            ])
            .padding(12)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // Trophies
            VStack(spacing: 0) {
                FDSectionHeader(icon: "trophy.fill", title: "Palmarès", badge: nil, color: FDTheme.amber)
                    .padding(.horizontal, 14).padding(.vertical, 10)

                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                let trophies: [(String, String, Int)] = [
                    ("trophy.fill", "Titres de champion", player.leagueTitles),
                    ("globe.europe.africa.fill", "Titres européens", player.cupTitles),
                    ("star.fill", "Ballon d'Or", player.awardCounts[FDAward.ballonDor.rawValue] ?? 0),
                    ("boot.fill", "Soulier d'Or", player.awardCounts[FDAward.soulierDor.rawValue] ?? 0),
                ]
                ForEach(trophies, id: \.1) { icon, label, count in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(FDTheme.amber)
                            .frame(width: 20)
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(FDTheme.textPrimary)
                        Spacer()
                        Text("\(count)")
                            .font(FDFont.mono(13, bold: true))
                            .foregroundStyle(count > 0 ? FDTheme.amber : .secondary)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                }
            }

            // Traits earned along the way — part of what made this career distinctive.
            if !player.traits.isEmpty {
                FDSectionHeader(icon: "person.crop.circle.fill.badge.checkmark", title: "Traits de caractère", color: FDTheme.primary)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(player.traits, id: \.self) { trait in
                        HStack(spacing: 5) {
                            Image(systemName: trait.icon).font(.system(size: 10, weight: .bold))
                            Text(trait.rawValue).font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(FDTheme.primary.opacity(0.15), in: Capsule())
                        .foregroundStyle(FDTheme.primary)
                    }
                }
                .padding(14)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            }

            // Season-by-season record, so reopening a career from the Historique tells the
            // whole story rather than just the totals.
            if !player.history.isEmpty {
                FDSectionHeader(icon: "clock.arrow.circlepath", title: "Saison par saison", badge: "\(player.history.count)", color: FDTheme.warning)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                HStack {
                    Text("SAISON").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
                    Text("Club").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                    Spacer()
                    Text("Buts").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).frame(width: 36)
                    Text("Note").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).frame(width: 36)
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Color.white.opacity(0.03))
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                ForEach(Array(player.history.enumerated().reversed()), id: \.offset) { idx, season in
                    HStack {
                        Text(fdSeasonLabelShort(season.season)).font(FDFont.mono(10)).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
                        Text(season.club).font(.caption.weight(.semibold)).lineLimit(1)
                        Spacer()
                        Text("\(season.goals)").font(FDFont.mono(12, bold: true)).foregroundStyle(FDTheme.success).frame(width: 36)
                        Text(String(format: "%.1f", season.avgRating))
                            .font(FDFont.mono(12, bold: true))
                            .foregroundStyle(FDTheme.amber)
                            .frame(width: 36)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    if idx > 0 {
                        Rectangle().fill(Color.white.opacity(0.03)).frame(height: 1)
                    }
                }
            }

            if let title = primaryActionTitle, let action = primaryAction {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                Button(action: action) { Text(title) }
                    .buttonStyle(FDPrimaryButtonStyle())
                    .padding(14)
            }
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

struct FDRetiredCard: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen

    var body: some View {
        if let p = engine.player {
            VStack(spacing: 12) {
                // The career is over — this is the one moment the player gets to sign it
                // before it takes its place in the local leaderboard.
                FDAliasPromptCard(engine: engine)

                FDCareerSummaryCard(player: p, primaryActionTitle: "Commencer une nouvelle carrière") {
                    engine.resetSave()
                    screen = .menu
                }
            }
        }
    }
}

private struct FDTrophyLine: View {
    let icon: String
    let label: String
    let value: Int
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(FDTheme.amber)
                .frame(width: 18)
            Text(label)
                .font(.caption)
                .foregroundStyle(FDTheme.textPrimary)
            Spacer()
            Text("\(value)")
                .font(FDFont.mono(13, bold: true))
                .foregroundStyle(value > 0 ? FDTheme.amber : .secondary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Carrière Tab

private enum FDCarriereSubTab: String, CaseIterable, Identifiable {
    case stats = "Stats"
    case palmares = "Palmarès"
    case distinctions = "Distinctions"
    case parcours = "Parcours"
    case entourage = "Entourage"
    var id: String { rawValue }
}

struct FDCarriereTab: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var subTab: FDCarriereSubTab = .stats
    @State private var showRetireConfirm = false

    var body: some View {
        NavigationView {
            Group {
                if let p = engine.player, p.retired {
                    ScrollView {
                        FDRetiredCard(engine: engine, screen: $screen)
                            .padding()
                    }
                } else if let p = engine.player {
                    // Fixed layout, no page-level scroll: the player block sits at the top and
                    // scrolls inside its own bounded box, so the narrative below it always
                    // stays exactly where the player expects to find it.
                    VStack(spacing: 10) {
                        VStack(spacing: 0) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.text.rectangle.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(FDTheme.primary)
                                Text("MON JOUEUR")
                                    .font(FDFont.body(11, black: true))
                                    .foregroundStyle(FDTheme.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(FDTheme.primary.opacity(0.07))

                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                            Picker("", selection: $subTab) {
                                ForEach(FDCarriereSubTab.allCases) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 10).padding(.vertical, 8)

                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                            ScrollView {
                                VStack(spacing: 10) {
                                    headerCard(p)

                                    switch subTab {
                                    case .stats: statsContent(p)
                                    case .palmares: palmaresContent(p)
                                    case .distinctions: distinctionsContent(p)
                                    case .parcours: parcoursContent(p)
                                    case .entourage: entourageContent(p)
                                    }

                                    retireCard(p)
                                }
                                .padding(10)
                            }
                        }
                        .frame(height: 300)
                        .background(FDTheme.card.opacity(0.65), in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                        )

                        // The narrative owns the rest of the screen and scrolls on its own.
                        ScrollView {
                            switch engine.currentScene {
                            case .none:
                                ProgressView().padding(.top, 40)
                            case .story(let scene):
                                FDStoryCard(engine: engine, scene: scene)
                            case .match(let result):
                                FDMatchCard(engine: engine, result: result)
                            case .season(let lines):
                                FDSeasonCard(engine: engine, lines: lines)
                            case .tournament(let summary):
                                FDTournamentCard(engine: engine, summary: summary)
                            case .outcome(let outcome):
                                FDOutcomeCard(engine: engine, outcome: outcome)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("Aucune carrière en cours")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(FDTheme.bg)
            .navigationTitle("Carrière")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Prendre ta retraite maintenant ?", isPresented: $showRetireConfirm, titleVisibility: .visible) {
                Button("Confirmer la retraite", role: .destructive) {
                    engine.voluntaryRetire()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action est définitive pour cette carrière.")
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Retire card — always present inside the player box, so ending a career is
    // reachable from the career screen itself and not buried in Options.

    @ViewBuilder
    private func retireCard(_ p: FDPlayer) -> some View {
        let canRetire = p.age >= 30
        VStack(spacing: 0) {
            FDSectionHeader(icon: "sunset.fill", title: "Raccrocher les crampons", color: FDTheme.warning)
                .padding(.horizontal, 14).padding(.vertical, 8)
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            VStack(spacing: 8) {
                Text(canRetire
                     ? "Ta carrière se termine ici et rejoint ton historique, avec les points et les pièces qu'elle a rapportés."
                     : "Tu pourras raccrocher à partir de 30 ans. Encore \(30 - p.age) saison(s) à écrire.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showRetireConfirm = true
                } label: {
                    Label("Raccrocher les crampons", systemImage: "figure.soccer")
                }
                .buttonStyle(FDDestructiveButtonStyle())
                .disabled(!canRetire)
                .opacity(canRetire ? 1 : 0.45)
            }
            .padding(12)
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(FDTheme.warning.opacity(0.18), lineWidth: 1))
    }

    // MARK: Header card — player overview with 4-stat grid

    private func headerCard(_ p: FDPlayer) -> some View {
        VStack(spacing: 0) {
            // Name / club
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(p.firstName) \(p.lastName)")
                        .font(FDFont.display(20))
                    Text("\(fdFlag(for: p.nationality)) \(p.nationality) · \(p.age) ans · \(p.position.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(fdFlag(for: p.club.country)) \(p.club.name), \(p.club.country)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(engine.overall(p))")
                        .font(FDFont.mono(26, bold: true))
                        .foregroundStyle(FDTheme.primary)
                    Text("NOTE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(FDTheme.primary.opacity(0.7))
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(FDTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(14)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // 4-stat grid: FCSManager style
            FDStatsGrid(cells: [
                .init(value: "\(p.careerGoals)", label: "Buts", icon: "soccerball"),
                .init(value: "\(p.careerApps)", label: "Matchs", icon: "calendar", color: FDTheme.primary),
                .init(value: "\(engine.potentialOverall(p))", label: "Potentiel", icon: "arrow.up.circle.fill", color: FDTheme.accentTeal),
                .init(value: fdFormatMoney(engine.marketValue(p)), label: "Valeur", icon: "eurosign.circle.fill", color: FDTheme.warning),
            ])
            .padding(12)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // Contract + style row
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(fdFormatMoney(p.contract.salary))
                        .font(FDFont.mono(14, bold: true))
                        .foregroundStyle(FDTheme.amber)
                    Text("SALAIRE / SEM")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 32)
                VStack(spacing: 2) {
                    Text(p.status.rawValue)
                        .font(FDFont.body(12, black: true))
                        .foregroundStyle(.white)
                    Text("STATUT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 32)
                VStack(spacing: 2) {
                    Text(p.style.rawValue)
                        .font(FDFont.body(12, black: true))
                        .foregroundStyle(FDTheme.primary)
                    Text("STYLE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
        }
        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: Stats content — condition pills + attribute bars

    private func statsContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 10) {
            // Condition section
            VStack(spacing: 0) {
                FDSectionHeader(icon: "waveform.path.ecg", title: "Condition", color: FDTheme.primary)
                    .padding(.horizontal, 14).padding(.vertical, 8)

                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                HStack(spacing: 0) {
                    FDCondPill(label: "Forme", value: p.cond.forme, color: FDTheme.primary)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                    FDCondPill(label: "Moral", value: p.cond.moral, color: .blue)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                    FDCondPill(label: "Confiance", value: p.cond.confiance, color: FDTheme.accentTeal)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                    FDCondPill(label: "Fatigue", value: p.cond.fatigue, color: .orange)
                }
                .padding(.vertical, 10)
            }
            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

            // Attributes by category (ordered by position weight)
            let orderedCats = [FDAttrCategory.tech, .phys, .ment, .def]
                .sorted { p.position.weights.value(for: $0) > p.position.weights.value(for: $1) }

            ForEach(Array(orderedCats.enumerated()), id: \.element) { idx, cat in
                let catAttrs = FDAttribute.allCases.filter { $0.category == cat }
                let catColor: Color = fdAttrCategoryColor(cat)

                VStack(spacing: 0) {
                    FDSectionHeader(
                        icon: fdAttrCategoryIcon(cat),
                        title: cat.label + (idx == 0 ? " · Clé" : ""),
                        badge: nil,
                        color: catColor
                    )
                    .padding(.horizontal, 14).padding(.vertical, 8)

                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                    VStack(spacing: 8) {
                        ForEach(catAttrs, id: \.self) { attr in
                            FDAttrBar(label: attr.label, value: p.attr(attr), color: catColor)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                }
                .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
            }
        }
        .padding(.top, 4)
    }

    // MARK: Palmarès content

    private func palmaresContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                FDSectionHeader(icon: "trophy.fill", title: "Palmarès", badge: nil, color: FDTheme.amber)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                let trophies: [(String, String, Int)] = [
                    ("trophy.fill", "Titres de champion", p.leagueTitles),
                    ("globe.europe.africa.fill", "Titres européens", p.cupTitles),
                    ("star.fill", "Ballon d'Or", p.awardCounts[FDAward.ballonDor.rawValue] ?? 0),
                    ("boot.fill", "Soulier d'Or", p.awardCounts[FDAward.soulierDor.rawValue] ?? 0),
                    ("flag.fill", "Caps internationaux", p.nationalCaps),
                ]
                ForEach(trophies, id: \.1) { icon, label, count in
                    FDTrophyLine(icon: icon, label: label, value: count)
                        .padding(.horizontal, 14)
                    Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                }
            }
            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

            // Career stats grid
            VStack(spacing: 0) {
                FDSectionHeader(icon: "chart.bar.fill", title: "Statistiques carrière", color: FDTheme.primary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                FDStatsGrid(cells: [
                    .init(value: "\(p.careerGoals)", label: "Buts", icon: "soccerball"),
                    .init(value: "\(p.careerAssists)", label: "Passes D.", icon: "arrow.triangle.turn.up.right.circle", color: FDTheme.primary),
                    .init(value: "\(p.careerApps)", label: "Matchs", icon: "calendar", color: FDTheme.accentTeal),
                    .init(value: "\(p.nationalCaps)", label: "Sélections", icon: "globe.europe.africa.fill", color: FDTheme.warning),
                ])
                .padding(12)
            }
            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
        }
        .padding(.top, 4)
    }

    // MARK: Distinctions content

    private func distinctionsContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                FDSectionHeader(icon: "medal.fill", title: "Distinctions individuelles", color: FDTheme.amber)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                if p.awardCounts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "medal")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text("Aucune distinction pour le moment.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    ForEach(p.awardCounts.sorted(by: { $0.key < $1.key }), id: \.key) { key, count in
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(FDTheme.amber)
                                .frame(width: 18)
                            Text(key.capitalized)
                                .font(.caption)
                                .foregroundStyle(FDTheme.textPrimary)
                            Spacer()
                            Text("×\(count)")
                                .font(FDFont.mono(13, bold: true))
                                .foregroundStyle(FDTheme.amber)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                    }
                }
            }
            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

            // Traits
            if !p.traits.isEmpty {
                VStack(spacing: 0) {
                    FDSectionHeader(icon: "person.crop.circle.fill.badge.checkmark", title: "Traits de caractère", color: FDTheme.primary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(p.traits, id: \.self) { trait in
                            HStack(spacing: 5) {
                                Image(systemName: trait.icon).font(.system(size: 10, weight: .bold))
                                Text(trait.rawValue).font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(FDTheme.primary.opacity(0.15), in: Capsule())
                            .foregroundStyle(FDTheme.primary)
                        }
                    }
                    .padding(14)
                }
                .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
            }
        }
        .padding(.top, 4)
    }

    // MARK: Parcours content — transfer history table

    private func parcoursContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 10) {
            // Current club
            VStack(spacing: 0) {
                FDSectionHeader(icon: "building.columns.fill", title: "Club actuel", color: FDTheme.primary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FDTheme.primary.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "soccerball")
                            .font(.system(size: 14))
                            .foregroundStyle(FDTheme.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.club.name).font(FDFont.body(14, black: true))
                        Text("\(fdFlag(for: p.club.country)) \(p.club.city), \(p.club.country)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(p.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(FDTheme.primary.opacity(0.15), in: Capsule())
                        .foregroundStyle(FDTheme.primary)
                }
                .padding(14)
            }
            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

            // Transfer history
            VStack(spacing: 0) {
                FDSectionHeader(icon: "arrow.triangle.2.circlepath", title: "Historique des transferts", badge: "\(p.transferHistory.count)", color: FDTheme.accentTeal)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                if p.transferHistory.isEmpty {
                    HStack {
                        Spacer()
                        Text("Aucun transfert enregistré.")
                            .font(.caption).foregroundStyle(.secondary)
                            .padding(.vertical, 16)
                        Spacer()
                    }
                } else {
                    ForEach(Array(p.transferHistory.enumerated()), id: \.offset) { idx, transfer in
                        FDParcoursRow(transfer: transfer)
                        if idx < p.transferHistory.count - 1 {
                            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        }
                    }
                }
            }
            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

            // Season history
            if !p.history.isEmpty {
                VStack(spacing: 0) {
                    FDSectionHeader(icon: "clock.arrow.circlepath", title: "Historique saisons", badge: "\(p.history.count)", color: FDTheme.warning)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    // Season header row
                    HStack {
                        Text("SAISON").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
                        Text("Club").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                        Spacer()
                        Text("Buts").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).frame(width: 36)
                        Text("Note").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).frame(width: 36)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Color.white.opacity(0.03))
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                    ForEach(Array(p.history.enumerated().reversed()), id: \.offset) { idx, season in
                        HStack {
                            Text(fdSeasonLabelShort(season.season)).font(FDFont.mono(10)).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
                            Text(season.club).font(.caption.weight(.semibold)).lineLimit(1)
                            Spacer()
                            Text("\(season.goals)").font(FDFont.mono(12, bold: true)).foregroundStyle(FDTheme.success).frame(width: 36)
                            Text(String(format: "%.1f", season.avgRating))
                                .font(FDFont.mono(12, bold: true))
                                .foregroundStyle(FDTheme.amber)
                                .frame(width: 36)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        if idx > 0 {
                            Rectangle().fill(Color.white.opacity(0.03)).frame(height: 1)
                        }
                    }
                }
                .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
            }
        }
        .padding(.top, 4)
    }

    // MARK: Entourage content — rivalry and relationships
    //
    // These belong to the player's career picture, not to app settings, so they live here
    // alongside stats and palmarès rather than in the Options tab.

    private func entourageContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 10) {
            if !p.rivalFirstName.isEmpty {
                VStack(spacing: 0) {
                    FDSectionHeader(icon: "flame.fill", title: "Rivalité", color: FDTheme.destructive)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(FDTheme.destructive.opacity(0.15)).frame(width: 36, height: 36)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(FDTheme.destructive)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(p.rivalFirstName) \(p.rivalLastName)")
                                .font(FDFont.body(14, black: true))
                            Text(p.rivalMomentum >= 75 ? "En état de grâce" : (p.rivalMomentum <= 25 ? "En difficulté" : "Saison stable"))
                                .font(.caption)
                                .foregroundStyle(p.rivalMomentum >= 75 ? FDTheme.destructive : (p.rivalMomentum <= 25 ? FDTheme.success : .secondary))
                        }
                        Spacer()
                    }
                    .padding(14)
                }
                .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
            }

            if !p.relDict.isEmpty {
                VStack(spacing: 0) {
                    FDSectionHeader(icon: "person.2.fill", title: "Relations", color: FDTheme.accentTeal)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    ForEach(p.relDict.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        FDAttrBar(label: key.capitalized, value: value, color: FDTheme.accentTeal)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                    }
                }
                .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Parcours Row

private struct FDParcoursRow: View {
    let transfer: FDTransferRecord

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.caption)
                .foregroundStyle(FDTheme.accentTeal)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(transfer.clubName).font(FDFont.body(12, black: true))
                Text(transfer.country).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(transfer.age) ans").font(FDFont.mono(11, bold: true)).foregroundStyle(.secondary)
                Text(fdFormatMoney(transfer.fee)).font(.caption2).foregroundStyle(FDTheme.amber)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
}

// MARK: - Meta tile

struct FDMetaTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(FDFont.mono(14, bold: true))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct FDConditionRow: View {
    let label: String
    let value: Int
    var color: Color

    var body: some View {
        FDAttrBar(label: label, value: value, color: color)
    }
}

struct FDAttributeRow: View {
    let attr: FDAttribute
    let value: Int

    var body: some View {
        let color: Color = attr.category == .tech ? FDTheme.accentTeal
            : attr.category == .phys ? FDTheme.primary
            : attr.category == .ment ? FDTheme.amber
            : .blue
        FDAttrBar(label: attr.label, value: value, color: color)
    }
}

// MARK: - Journal Tab

struct FDJournalTab: View {
    @ObservedObject var engine: FDGameEngine

    var body: some View {
        NavigationView {
            Group {
                if let p = engine.player {
                    if p.journal.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "newspaper")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("Aucun événement pour l'instant.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(p.journal.reversed().enumerated()), id: \.offset) { idx, entry in
                                    FDJournalRow(entry: entry)
                                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                                }
                            }
                            .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                            .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
                            .padding(.horizontal, 14)
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    Text("Aucune carrière").foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(FDTheme.bg)
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

private struct FDJournalRow: View {
    let entry: FDJournalEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(FDTheme.accentTeal.opacity(0.15))
                    .frame(width: 34, height: 34)
                Text(entry.icon)
                    .font(.system(size: 15))
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("SAISON \(entry.season)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(FDTheme.accentTeal)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(entry.age) ans")
                        .font(FDFont.mono(10))
                        .foregroundStyle(.secondary)
                }
                Text(entry.text)
                    .font(.caption)
                    .foregroundStyle(FDTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Options Tab

struct FDOptionsTab: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen

    @State private var showRetireConfirm = false
    @State private var showAbandonConfirm = false

    private var canRetire: Bool { (engine.player?.age ?? 0) >= 30 }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // There is no account and no cloud save — a career is simply carried on,
                    // ended on the player's terms, or abandoned. Those are the only three
                    // things this screen offers.
                    VStack(spacing: 0) {
                        FDSectionHeader(icon: "sunset.fill", title: "Finir ma carrière", color: FDTheme.warning)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        FDOptionRow(icon: "figure.soccer", label: "Raccrocher les crampons", color: FDTheme.warning, disabled: !canRetire) {
                            showRetireConfirm = true
                        }
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        Text(canRetire
                             ? "Ta carrière se termine ici et rejoint ton historique, avec les points et les pièces qu'elle a rapportés."
                             : "Tu pourras raccrocher à partir de 30 ans.")
                            .font(.caption2).foregroundStyle(.secondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    VStack(spacing: 0) {
                        FDSectionHeader(icon: "xmark.circle.fill", title: "Abandonner", color: FDTheme.destructive)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        FDOptionRow(icon: "trash.fill", label: "Abandonner cette carrière", color: FDTheme.destructive) {
                            showAbandonConfirm = true
                        }
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        Text("La carrière est effacée sans rejoindre ton historique — elle ne rapporte ni points ni pièces.")
                            .font(.caption2).foregroundStyle(.secondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    VStack(spacing: 0) {
                        FDSectionHeader(icon: "info.circle.fill", title: "À propos", color: .secondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        Text("FCS-Destiny — aucun compte, aucune inscription. Ta progression est enregistrée automatiquement sur cet appareil et nulle part ailleurs.")
                            .font(.caption).foregroundStyle(.secondary)
                            .padding(14)
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(FDTheme.bg)
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Raccrocher les crampons ?", isPresented: $showRetireConfirm, titleVisibility: .visible) {
                Button("Confirmer la retraite", role: .destructive) { engine.voluntaryRetire() }
                Button("Annuler", role: .cancel) {}
            } message: { Text("Ta carrière se termine ici et rejoint ton historique.") }
            .confirmationDialog("Abandonner cette carrière ?", isPresented: $showAbandonConfirm, titleVisibility: .visible) {
                Button("Abandonner", role: .destructive) {
                    engine.resetSave()
                    screen = .menu
                }
                Button("Annuler", role: .cancel) {}
            } message: { Text("Elle sera effacée sans rejoindre ton historique.") }
        }
        .navigationViewStyle(.stack)
    }
}

private struct FDOptionRow: View {
    let icon: String
    let label: String
    var color: Color = FDTheme.primary
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(disabled ? .secondary : color)
                    .frame(width: 28)
                Text(label)
                    .font(FDFont.body(14))
                    .foregroundStyle(disabled ? .secondary : FDTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .buttonStyle(FDRowButtonStyle())
        .disabled(disabled)
    }
}

// MARK: - Flow layout for traits

