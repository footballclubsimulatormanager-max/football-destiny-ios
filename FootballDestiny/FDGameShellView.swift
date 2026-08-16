import SwiftUI
import UIKit
import Foundation

struct FDGameShellView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var selectedTab = 0

    var body: some View {
        // The status header sits above the TabView rather than being inset into it. As a
        // safe-area inset it shifted the whole tab content down while the tabs kept their
        // full height, which left a band of background at the bottom of every screen.
        VStack(spacing: 0) {
            FDStatusHeader(engine: engine)

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
        }
        .background(FDTheme.bg.ignoresSafeArea())
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
                        HStack(spacing: 5) {
                            Text("\(p.firstName) \(p.lastName)")
                                .font(FDFont.body(17, black: true))
                            Text("\(engine.overall(p))")
                                .font(FDFont.mono(16, bold: true))
                                .foregroundStyle(FDTheme.primary)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(FDTheme.primary.opacity(0.15), in: Capsule())
                        }
                        Text("\(fdFlag(for: p.club.country)) \(p.club.name)  ·  \(p.position.rawValue)")
                            .font(.subheadline)
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
                        .font(FDFont.mono(16, bold: true))
                        HStack(spacing: 3) {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundStyle(FDTheme.primary)
                            Text("\(p.cond.forme)%")
                                .foregroundStyle(FDTheme.primary)
                        }
                        .font(FDFont.mono(16, bold: true))
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
                    // The progress bar above already shows where the season stands; the week
                    // number was noise on top of it.
                    Text("\(fdSeasonLabel(p.calendar.season))  ·  \(p.age) ans")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill").font(.system(size: 13))
                        Text("Rép. \(p.cond.reputation)")
                    }
                    .foregroundStyle(FDTheme.amber)
                }
                .font(.subheadline.weight(.medium))
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
            .font(.subheadline.weight(.semibold))
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
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(FDFont.body(16, black: true))
                .foregroundStyle(color)
            Spacer()
            if let b = badge {
                Text(b)
                    .font(FDFont.mono(14, bold: true))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(FDTheme.headerWash(color), in: RoundedRectangle(cornerRadius: FDTheme.radiusMD))
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
                VStack(spacing: 2) {
                    Image(systemName: cell.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(cell.color)
                    Text(cell.value)
                        .font(FDFont.mono(18, bold: true))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(cell.label.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                if idx < cells.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 32)
                }
            }
        }
        .fdCardSurface()
    }
}

/// The season-by-season record, shared by the career summary and the Parcours tab.
/// Deliberately dense: four numeric columns (matchs, buts, passes, note) on one tight row
/// per season, with the real season span rather than an index.
struct FDSeasonTable: View {
    let history: [FDSeasonRecord]

    private let colWidth: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("SAISON")
                    .frame(width: 42, alignment: .leading)
                Text("CLUB")
                Spacer(minLength: 4)
                Text("M").frame(width: colWidth, alignment: .trailing)
                Text("B").frame(width: colWidth, alignment: .trailing)
                Text("P").frame(width: colWidth, alignment: .trailing)
                Text("NOTE").frame(width: 34, alignment: .trailing)
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(Color.white.opacity(0.03))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            ForEach(Array(history.enumerated().reversed()), id: \.offset) { idx, season in
                HStack(spacing: 0) {
                    Text(fdSeasonLabelShort(season.season))
                        .font(FDFont.mono(14))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .leading)
                    Text(season.club)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FDTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    Text("\(season.apps)")
                        .font(FDFont.mono(16))
                        .foregroundStyle(.secondary)
                        .frame(width: colWidth, alignment: .trailing)
                    Text("\(season.goals)")
                        .font(FDFont.mono(16, bold: true))
                        .foregroundStyle(FDTheme.success)
                        .frame(width: colWidth, alignment: .trailing)
                    Text("\(season.assists)")
                        .font(FDFont.mono(16, bold: true))
                        .foregroundStyle(FDTheme.primary)
                        .frame(width: colWidth, alignment: .trailing)
                    Text(String(format: "%.1f", season.avgRating))
                        .font(FDFont.mono(16, bold: true))
                        .foregroundStyle(FDTheme.amber)
                        .frame(width: 34, alignment: .trailing)
                }
                .padding(.horizontal, 12).padding(.vertical, 5)

                if idx > 0 {
                    Rectangle().fill(Color.white.opacity(0.03)).frame(height: 1)
                }
            }
        }
    }
}

/// Compact attribute bar row — FCSManager style with thin progress bar
/// One statistic as a name and a figure — no progress bar. The bar carried no
/// information the number didn't already give and ate the width that lets two stats sit
/// side by side, so stats now pack into a two-column grid instead of a stack of rows.
private struct FDAttrBar: View {
    let label: String
    let value: Int
    var max: Int = 100
    var color: Color = FDTheme.primary

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(FDTheme.textMuted.opacity(0.7))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(value)")
                .font(FDFont.mono(14, bold: true))
                .foregroundStyle(FDTheme.statColor(value))
                .frame(width: 24, alignment: .trailing)
                .animation(.fdSoft, value: value)
        }
        .padding(.vertical, 3)
    }
}

/// Two-column layout shared by every stat block, so a category fits in half the height.
private let fdStatColumns = [
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
]

/// Compact condition pill — inline in a row
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
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                Text(char)
                    .font(FDFont.body(19, black: true))
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
            // Header — the scene announces itself like the top of an article.
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(fdSceneColor(scene.category).opacity(0.18))
                        .frame(width: 42, height: 42)
                    Image(systemName: fdSceneSymbol(scene.category))
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(fdSceneColor(scene.category))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.category.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(fdSceneColor(scene.category))
                    Text(scene.location)
                        .font(FDFont.headline(20, italic: false))
                        .foregroundStyle(.white)
                        .lineLimit(2).minimumScaleFactor(0.75)
                    if scene.character != "—" && !scene.character.isEmpty {
                        Text(scene.character)
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(FDTheme.headerWash(fdSceneColor(scene.category)))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // The scene takes the height it needs and no more, so the choices sit right
            // under it instead of being pushed to the bottom of the card with a hole in
            // between. A very long scene shrinks slightly rather than pushing them off.
            Text(scene.text)
                .font(FDFont.story(20))
                .lineSpacing(6)
                .foregroundStyle(FDTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            VStack(spacing: 10) {
                ForEach(Array(scene.choices.enumerated()), id: \.offset) { idx, choice in
                    // Each choice is a filled button in its own colour — pressable at a
                    // glance, no hunting for the tappable part of a row.
                    let tint = fdChoiceTint(index: idx, category: scene.category)
                    Button {
                        FDHaptics.tap()
                        engine.resolveChoice(choice, category: scene.category)
                    } label: {
                        VStack(spacing: 3) {
                            if let tag = choice.tag {
                                Text(tag.uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(0.9)
                                    .foregroundStyle(tint.opacity(0.85))
                            } else if let trait = choice.trait {
                                Text(trait.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(0.9)
                                    .foregroundStyle(tint.opacity(0.85))
                            }
                            Text(choice.label)
                                .font(FDFont.body(18, black: true))
                                .foregroundStyle(tint)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(tint.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(tint.opacity(0.38), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(FDRowButtonStyle())
                }
            }
            .padding(.horizontal, 11)
            .padding(.bottom, 12)

            Spacer(minLength: 0)
        }
        // The scene card owns the bottom half of the screen down to the tab bar:
        // it stretches to whatever height it is offered, content pinned to the top.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fdCardSurface()
    }
}


/// Colour for a choice button. The first choice wears the scene's own colour, the following
/// ones take the rest of the palette, so three options are told apart at a glance.
private func fdChoiceTint(index: Int, category: String) -> Color {
    let palette: [Color] = [fdSceneColor(category), FDTheme.primary, FDTheme.success, FDTheme.warning]
    return palette[index % palette.count]
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
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(fdSceneColor(outcome.category))
                Text(outcome.category.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(fdSceneColor(outcome.category))
                Spacer()
                Text("RÉSULTAT")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FDTheme.card.opacity(0.5))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            Text(outcome.narrative)
                .font(FDFont.story(18))
                .lineSpacing(3)
                .foregroundStyle(FDTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .minimumScaleFactor(0.72)
                .padding(14)

            if !outcome.pills.isEmpty {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(outcome.pills, id: \.valueText) { pill in
                            HStack(spacing: 4) {
                                Image(systemName: pill.positive ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 14, weight: .bold))
                                Text(pill.label)
                                    .font(.subheadline.weight(.semibold))
                                Text(pill.valueText)
                                    .font(FDFont.mono(16, bold: true))
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
        // The scene card owns the bottom half of the screen down to the tab bar:
        // it stretches to whatever height it is offered, content pinned to the top.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fdCardSurface()
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
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(FDTheme.primary)
                Text("MATCH")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FDTheme.primary)
                Spacer()
                let isWin = result.teamScore > result.oppScore
                let isDraw = result.teamScore == result.oppScore
                Text(isWin ? "V" : isDraw ? "N" : "D")
                    .font(FDFont.mono(16, bold: true))
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
                        .font(FDFont.body(17, black: true))
                    Text("Niveau adverse : \(result.opponentLevel)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(result.teamScore) – \(result.oppScore)")
                    .font(FDFont.mono(26, bold: true))
                    .foregroundStyle(.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(result.minutes > 0 ? String(format: "%.1f", result.rating) : "—")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FDTheme.accentTeal)
                    Text("Note")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)

            if result.goals > 0 {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                HStack(spacing: 6) {
                    Image(systemName: "soccerball").font(.subheadline).foregroundStyle(FDTheme.success)
                    Text("\(result.goals) but\(result.goals > 1 ? "s" : "") marqué\(result.goals > 1 ? "s" : "")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FDTheme.success)
                    if result.assists > 0 {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.triangle.turn.up.right.circle").font(.subheadline).foregroundStyle(FDTheme.primary)
                        Text("\(result.assists) passe\(result.assists > 1 ? "s" : "") décisive\(result.assists > 1 ? "s" : "")")
                            .font(.subheadline.weight(.semibold))
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
                        .font(FDFont.body(18, black: true))
                    Image(systemName: "arrow.right")
                    Spacer()
                }
                .padding(.vertical, 12)
                .foregroundStyle(FDTheme.primary)
            }
            .buttonStyle(FDRowButtonStyle())
        }
        // The scene card owns the bottom half of the screen down to the tab bar:
        // it stretches to whatever height it is offered, content pinned to the top.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fdCardSurface()
    }
}

struct FDMatchStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(FDFont.mono(19, bold: true))
            Text(label.uppercased()).font(.subheadline.weight(.bold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Season Card

struct FDSeasonCard: View {
    @ObservedObject var engine: FDGameEngine
    let report: FDSeasonReport

    /// The engine's lines already start with their own emoji; the display keeps it and
    /// never stacks a second icon on top, which is what made the old list read like code.
    private func splitEmoji(_ line: String) -> (String, String) {
        guard let first = line.unicodeScalars.first, first.properties.isEmoji, first.value > 0x238C else {
            return ("•", line)
        }
        let symbol = String(line.prefix(while: { !$0.isWhitespace }))
        let rest = line.dropFirst(symbol.count).trimmingCharacters(in: .whitespaces)
        return (symbol, rest)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("📰")
                Text("BILAN DE SAISON")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FDTheme.amber)
                Spacer()
                Text("\(report.seasonLabel) · \(report.club)")
                    .font(FDFont.mono(14)).foregroundStyle(.secondary)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(FDTheme.amber.opacity(0.08))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // The written piece, in the serif — a chronicle, not a log.
                    VStack(alignment: .leading, spacing: 7) {
                        Text("« \(report.headline) »")
                            .font(FDFont.story(19, bold: true, italic: true))
                            .foregroundStyle(FDTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(report.article)
                            .font(FDFont.story(17))
                            .lineSpacing(3)
                            .foregroundStyle(FDTheme.textPrimary.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)

                    // The four figures of the year, as tiles.
                    HStack(spacing: 8) {
                        FDSeasonTile(value: "\(report.apps)", label: "MATCHS", color: FDTheme.primary)
                        FDSeasonTile(value: "\(report.goals)", label: "BUTS", color: FDTheme.success)
                        FDSeasonTile(value: "\(report.assists)", label: "PASSES DÉC.", color: FDTheme.accentTeal)
                        FDSeasonTile(value: String(format: "%.1f", report.rating), label: "NOTE", color: FDTheme.amber)
                    }
                    .padding(.horizontal, 12)

                    if report.leaguePosition > 0 {
                        HStack(spacing: 6) {
                            Text("🏁")
                            Text("Championnat :")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("\(report.leaguePosition)\(report.leaguePosition == 1 ? "er" : "e")")
                                .font(FDFont.body(17, black: true))
                                .foregroundStyle(report.leaguePosition <= 3 ? FDTheme.amber : FDTheme.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                    }

                    if !report.lines.isEmpty {
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        VStack(alignment: .leading, spacing: 9) {
                            ForEach(report.lines, id: \.self) { line in
                                let parts = splitEmoji(line)
                                HStack(alignment: .top, spacing: 8) {
                                    Text(parts.0)
                                        .font(.system(size: 17))
                                        .frame(width: 20, alignment: .center)
                                    Text(parts.1)
                                        .font(.subheadline)
                                        .foregroundStyle(FDTheme.textPrimary.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 4)
                    }
                }
                .padding(.bottom, 10)
            }

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            Button {
                FDHaptics.tap()
                engine.continueAfterSeason()
            } label: {
                HStack {
                    Spacer()
                    Text(engine.player?.retired == true ? "Voir le résumé" : "Nouvelle saison →")
                        .font(FDFont.body(18, black: true))
                        .foregroundStyle(FDTheme.primary)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(FDRowButtonStyle())
        }
        // The scene card owns the bottom half of the screen down to the tab bar:
        // it stretches to whatever height it is offered, content pinned to the top.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fdCardSurface()
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(FDTheme.amber.opacity(0.15), lineWidth: 1)
        )
    }
}

/// One of the four figures at the top of a season report.
private struct FDSeasonTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(FDFont.mono(20, bold: true))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(FDTheme.bg.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
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
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(summary.champion ? FDTheme.amber : FDTheme.accentTeal)
                VStack(alignment: .leading, spacing: 1) {
                    Text(summary.competitionName.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(summary.champion ? FDTheme.amber : FDTheme.accentTeal)
                    Text(summary.champion ? "CHAMPION" : summary.stageReached)
                        .font(FDFont.body(17, black: true))
                }
                Spacer()
                Text(String(summary.year))
                    .font(FDFont.mono(16)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background((summary.champion ? FDTheme.amber : FDTheme.accentTeal).opacity(0.08))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            Text(summary.narrative)
                .font(FDFont.story(18))
                .lineSpacing(3)
                .foregroundStyle(FDTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
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
                        .font(FDFont.body(18, black: true))
                        .foregroundStyle(FDTheme.primary)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(FDRowButtonStyle())
        }
        // The scene card owns the bottom half of the screen down to the tab bar:
        // it stretches to whatever height it is offered, content pinned to the top.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fdCardSurface()
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
                        .font(.system(size: 21))
                        .foregroundStyle(FDTheme.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(player.firstName) \(player.lastName)")
                        .font(FDFont.display(19))
                    // The leaderboard only shows the signature; the real name and the
                    // signature appear together here, on the career sheet.
                    if !player.alias.isEmpty {
                        Text("signé « \(player.alias) »")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FDTheme.amber)
                    }
                    Text("\(fdFlag(for: player.nationality)) \(player.nationality) · \(player.position.rawValue) · retraité à \(player.age) ans")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(FDTheme.card.opacity(0.5))

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            // The career, written up: the same press-piece treatment as an end of season,
            // so a career closes on a text and not on a table.
            let chronicle = fdCareerChronicle(player: player)
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Text("📰")
                    Text("LA CHRONIQUE")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(FDTheme.amber)
                    Spacer()
                }
                Text("« \(chronicle.headline) »")
                    .font(FDFont.story(19, bold: true, italic: true))
                    .foregroundStyle(FDTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(chronicle.article)
                    .font(FDFont.story(17))
                    .lineSpacing(3)
                    .foregroundStyle(FDTheme.textPrimary.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)

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
                            .font(.subheadline)
                            .foregroundStyle(FDTheme.amber)
                            .frame(width: 20)
                        Text(label)
                            .font(.subheadline)
                            .foregroundStyle(FDTheme.textPrimary)
                        Spacer()
                        Text("\(count)")
                            .font(FDFont.mono(17, bold: true))
                            .foregroundStyle(count > 0 ? FDTheme.amber : .secondary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                }
            }

            // Traits earned along the way — part of what made this career distinctive.
            if !player.traits.isEmpty {
                FDSectionHeader(icon: "person.crop.circle.fill.badge.checkmark", title: "Traits de caractère", color: FDTheme.primary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(player.traits, id: \.self) { trait in
                        HStack(spacing: 5) {
                            Image(systemName: trait.icon).font(.system(size: 14, weight: .bold))
                            Text(trait.rawValue).font(.subheadline.weight(.semibold))
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
                    .padding(.horizontal, 10).padding(.vertical, 6)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                FDSeasonTable(history: player.history)
            }

            if let title = primaryActionTitle, let action = primaryAction {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                Button(action: action) { Text(title) }
                    .buttonStyle(FDPrimaryButtonStyle())
                    .padding(14)
            }
        }
        .fdCardSurface()
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


// MARK: - Carrière Tab

private enum FDCarriereMainTab: String, CaseIterable, Identifiable {
    case carriere = "Carrière"
    case stats = "Stats"
    var id: String { rawValue }
}

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
    @State private var mainTab: FDCarriereMainTab = .carriere
    @State private var subTab: FDCarriereSubTab = .stats

    var body: some View {
        // No NavigationView here: nothing on this tab navigates, and its bar only stole
        // height. The background is applied as a modifier rather than as a ZStack layer
        // ignoring the safe areas — that layer stretched the whole container and pulled the
        // content up under the status bar.
        Group {
            if let p = engine.player, p.retired {
                ScrollView {
                    FDRetiredCard(engine: engine, screen: $screen)
                        .padding()
                }
            } else if let p = engine.player {
                // Two views, not one crowded screen. "Carrière" is the story: who the
                // player is, then the scene, which owns everything below. "Stats" holds
                // the five detail sections in the same shape, full height.
                VStack(spacing: 8) {
                    Picker("", selection: $mainTab) {
                        ForEach(FDCarriereMainTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch mainTab {
                    case .carriere: carriereView(p)
                    case .stats: statsView(p)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FDTheme.bg)
    }

    /// A labelled bar, used only by the player sheet header.
    private func fdGauge(label: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 2)
                Text("\(value)")
                    .font(FDFont.mono(13, bold: true))
                    .foregroundStyle(color)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(color)
                        .frame(width: g.size.width * CGFloat(min(max(value, 0), 100)) / 100)
                        .animation(.fdSoft, value: value)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: The two views

    /// The story view: a compact identity strip, then the scene, which takes the rest of the
    /// screen down to the tab bar.
    @ViewBuilder
    private func carriereView(_ p: FDPlayer) -> some View {
        VStack(spacing: 8) {
            // The player's state, permanently on screen: the four figures that change week
            // to week and that every choice is about. The name and club are already in the
            // status bar above, so they are not repeated here.
            HStack(spacing: 7) {
                FDStateChip(value: p.cond.forme, label: "FORME", color: FDTheme.success)
                FDStateChip(value: p.cond.moral, label: "MORAL", color: FDTheme.primary)
                FDStateChip(value: p.cond.confiance, label: "CONFIANCE", color: FDTheme.accentTeal)
                FDStateChip(value: p.cond.fatigue, label: "FATIGUE", color: FDTheme.warning)
            }

            sceneCard
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
        }
    }

    /// The detail view: the same five sections as before, but with the whole screen instead
    /// of a third of it, and the retirement card at the bottom.
    @ViewBuilder
    private func statsView(_ p: FDPlayer) -> some View {
        VStack(spacing: 0) {
            // The card header, the way a player sheet reads: who, where, how good, and the
            // two gauges that change week to week.
            VStack(spacing: 7) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(p.firstName) \(p.lastName)")
                            .font(FDFont.display(20))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("\(fdFlag(for: p.nationality)) \(p.nationality)  ·  \(p.age) ans  ·  \(p.position.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("\(fdFlag(for: p.club.country)) \(p.club.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: 3) {
                        Text("\(engine.overall(p))")
                            .font(FDFont.mono(21, bold: true))
                            .foregroundStyle(FDTheme.primary)
                        Text("POT. \(engine.potentialOverall(p))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(FDTheme.amber)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(FDTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }

                HStack(spacing: 9) {
                    fdGauge(label: "FORME", value: p.cond.forme, color: FDTheme.success)
                    fdGauge(label: "MORAL", value: p.cond.moral, color: FDTheme.accentTeal)
                    fdGauge(label: "CONF.", value: p.cond.confiance, color: FDTheme.primary)
                    fdGauge(label: "FATIGUE", value: p.cond.fatigue, color: .orange)
                }
            }
            .padding(.horizontal, 11).padding(.vertical, 9)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            Picker("", selection: $subTab) {
                ForEach(FDCarriereSubTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 7).padding(.vertical, 6)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            ScrollView {
                VStack(spacing: 8) {
                    switch subTab {
                    case .stats: statsContent(p)
                    case .palmares: palmaresContent(p)
                    case .distinctions: distinctionsContent(p)
                    case .parcours: parcoursContent(p)
                    case .entourage: entourageContent(p)
                    }
                }
                .padding(7)
                .id(subTab)
            }

            // The gold footer of a player sheet: the season and what the career is worth.
            HStack {
                Text(fdSeasonLabelShort(p.calendar.season))
                    .font(FDFont.body(15, black: true))
                Spacer()
                Text("Fortune : \(fdFormatMoney(p.money))")
                    .font(FDFont.mono(15, bold: true))
            }
            .foregroundStyle(FDTheme.bg)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(
                LinearGradient(colors: [FDTheme.amber, FDTheme.warning],
                               startPoint: .leading, endPoint: .trailing)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FDTheme.card.opacity(0.6), in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: FDTheme.radiusCard)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    /// Whatever the engine is currently showing.
    @ViewBuilder
    private var sceneCard: some View {
        switch engine.currentScene {
        case .none:
            ProgressView().frame(maxHeight: .infinity)
        case .story(let scene):
            FDStoryCard(engine: engine, scene: scene)
        case .match(let result):
            FDMatchCard(engine: engine, result: result)
        case .season(let report):
            FDSeasonCard(engine: engine, report: report)
        case .tournament(let summary):
            FDTournamentCard(engine: engine, summary: summary)
        case .outcome(let outcome):
            // Without an explicit continue action the outcome card renders no button and
            // the career dead-ends on the very first resolved choice.
            FDOutcomeCard(
                engine: engine,
                outcome: outcome,
                primaryActionTitle: "Continuer",
                primaryAction: { engine.continueAfterOutcome() }
            )
        }
    }

    // MARK: Retire card — always present inside the player box, so ending a career is
    // reachable from the career screen itself and not buried in Options.

    @ViewBuilder
    // MARK: Stats content — condition pills + attribute bars

    /// Everything about the player's shape, sized to fit the player box without scrolling:
    /// one card, a condition strip, then all sixteen attributes in a three-column grid with
    /// thin category separators instead of four stacked sub-cards.
    private func statsContent(_ p: FDPlayer) -> some View {
        let orderedCats = [FDAttrCategory.tech, .phys, .ment, .def]
            .sorted { p.position.weights.value(for: $0) > p.position.weights.value(for: $1) }

        return VStack(spacing: 0) {
            ForEach(Array(orderedCats.enumerated()), id: \.element) { idx, cat in
                let catAttrs = FDAttribute.allCases.filter { $0.category == cat }
                let catColor: Color = fdAttrCategoryColor(cat)

                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                HStack(spacing: 4) {
                    Image(systemName: fdAttrCategoryIcon(cat))
                        .font(.system(size: 13, weight: .bold))
                    Text(cat.label.uppercased() + (idx == 0 ? " · CLÉ" : ""))
                        .font(.system(size: 13, weight: .black))
                    Spacer()
                }
                .foregroundStyle(catColor)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(FDTheme.headerWash(catColor))

                LazyVGrid(columns: fdStatColumns, spacing: 2) {
                    ForEach(catAttrs, id: \.self) { attr in
                        FDAttrBar(label: attr.label, value: p.attr(attr), color: catColor)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
            }
        }
        .fdCardSurface()
    }

    // MARK: Palmarès content

    /// Career totals and honours in a single card, sized like the stats tab so the whole
    /// tab lands inside the player box.
    private func palmaresContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 0) {
            FDStatsGrid(cells: [
                .init(value: "\(p.careerGoals)", label: "Buts", icon: "soccerball"),
                .init(value: "\(p.careerAssists)", label: "Passes D.", icon: "arrow.triangle.turn.up.right.circle", color: FDTheme.primary),
                .init(value: "\(p.careerApps)", label: "Matchs", icon: "calendar", color: FDTheme.accentTeal),
                .init(value: "\(p.nationalCaps)", label: "Sélections", icon: "globe.europe.africa.fill", color: FDTheme.warning),
            ])

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            HStack(spacing: 4) {
                Image(systemName: "trophy.fill").font(.system(size: 13, weight: .bold))
                Text("PALMARÈS").font(.system(size: 13, weight: .black))
                Spacer()
            }
            .foregroundStyle(FDTheme.amber)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(FDTheme.headerWash(FDTheme.amber))

            let trophies: [(String, String, Int)] = [
                ("trophy.fill", "Champion", p.leagueTitles),
                ("globe.europe.africa.fill", "Européens", p.cupTitles),
                ("star.fill", "Ballon d'Or", p.awardCounts[FDAward.ballonDor.rawValue] ?? 0),
                ("boot.fill", "Soulier d'Or", p.awardCounts[FDAward.soulierDor.rawValue] ?? 0),
                ("flag.fill", "Sélections", p.nationalCaps),
                ("sparkles", "Révélation", p.awardCounts[FDAward.revelation.rawValue] ?? 0),
            ]
            LazyVGrid(columns: fdStatColumns, spacing: 3) {
                ForEach(trophies, id: \.1) { icon, label, count in
                    HStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(count > 0 ? FDTheme.amber : Color.secondary)
                        Text(label)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 1)
                        Text("\(count)")
                            .font(FDFont.mono(16, bold: true))
                            .foregroundStyle(count > 0 ? FDTheme.amber : Color.secondary)
                    }
                    .padding(.horizontal, 4).padding(.vertical, 2.5)
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
        }
        .fdCardSurface()
    }

    // MARK: Distinctions content

    private func distinctionsContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                FDSectionHeader(icon: "medal.fill", title: "Distinctions individuelles", color: FDTheme.amber)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                if p.awardCounts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "medal")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text("Aucune distinction pour le moment.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    ForEach(p.awardCounts.sorted(by: { $0.key < $1.key }), id: \.key) { key, count in
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.subheadline)
                                .foregroundStyle(FDTheme.amber)
                                .frame(width: 18)
                            Text(key.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(FDTheme.textPrimary)
                            Spacer()
                            Text("×\(count)")
                                .font(FDFont.mono(17, bold: true))
                                .foregroundStyle(FDTheme.amber)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                    }
                }
            }
            .fdCardSurface()

            // Traits
            if !p.traits.isEmpty {
                VStack(spacing: 0) {
                    FDSectionHeader(icon: "person.crop.circle.fill.badge.checkmark", title: "Traits de caractère", color: FDTheme.primary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(p.traits, id: \.self) { trait in
                            HStack(spacing: 5) {
                                Image(systemName: trait.icon).font(.system(size: 14, weight: .bold))
                                Text(trait.rawValue).font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(FDTheme.primary.opacity(0.15), in: Capsule())
                            .foregroundStyle(FDTheme.primary)
                        }
                    }
                    .padding(14)
                }
                .fdCardSurface()
            }
        }
        .padding(.top, 4)
    }

    // MARK: Parcours content — transfer history table

    private func parcoursContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 8) {
            // Current club
            VStack(spacing: 0) {
                FDSectionHeader(icon: "building.columns.fill", title: "Club actuel", color: FDTheme.primary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FDTheme.primary.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "soccerball")
                            .font(.system(size: 18))
                            .foregroundStyle(FDTheme.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.club.name).font(FDFont.body(18, black: true))
                        Text("\(fdFlag(for: p.club.country)) \(p.club.city), \(p.club.country)").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(p.status.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(FDTheme.primary.opacity(0.15), in: Capsule())
                        .foregroundStyle(FDTheme.primary)
                }
                .padding(14)
            }
            .fdCardSurface()

            // Transfer history
            VStack(spacing: 0) {
                FDSectionHeader(icon: "arrow.triangle.2.circlepath", title: "Historique des transferts", badge: "\(p.transferHistory.count)", color: FDTheme.accentTeal)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                if p.transferHistory.isEmpty {
                    HStack {
                        Spacer()
                        Text("Aucun transfert enregistré.")
                            .font(.subheadline).foregroundStyle(.secondary)
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
            .fdCardSurface()

            // Season history
            if !p.history.isEmpty {
                VStack(spacing: 0) {
                    FDSectionHeader(icon: "clock.arrow.circlepath", title: "Historique saisons", badge: "\(p.history.count)", color: FDTheme.warning)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    FDSeasonTable(history: p.history)
                }
                .fdCardSurface()
            }
        }
        .padding(.top, 4)
    }

    // MARK: Entourage content — rivalry and relationships
    //
    // These belong to the player's career picture, not to app settings, so they live here
    // alongside stats and palmarès rather than in the Options tab.

    private func entourageContent(_ p: FDPlayer) -> some View {
        VStack(spacing: 0) {
            if !p.rivalFirstName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.system(size: 13, weight: .bold))
                    Text("RIVALITÉ").font(.system(size: 13, weight: .black))
                    Spacer()
                }
                .foregroundStyle(FDTheme.destructive)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(FDTheme.headerWash(FDTheme.destructive))

                HStack(spacing: 9) {
                    ZStack {
                        Circle().fill(FDTheme.destructive.opacity(0.15)).frame(width: 28, height: 28)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(FDTheme.destructive)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(p.rivalFirstName) \(p.rivalLastName)")
                            .font(FDFont.body(16, black: true))
                        Text(p.rivalMomentum >= 75 ? "En état de grâce" : (p.rivalMomentum <= 25 ? "En difficulté" : "Saison stable"))
                            .font(.system(size: 14))
                            .foregroundStyle(p.rivalMomentum >= 75 ? FDTheme.destructive : (p.rivalMomentum <= 25 ? FDTheme.success : .secondary))
                    }
                    Spacer()
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
            }

            if !p.relDict.isEmpty {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill").font(.system(size: 13, weight: .bold))
                    Text("RELATIONS").font(.system(size: 13, weight: .black))
                    Spacer()
                }
                .foregroundStyle(FDTheme.accentTeal)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(FDTheme.headerWash(FDTheme.accentTeal))

                LazyVGrid(columns: fdStatColumns, spacing: 2) {
                    ForEach(p.relDict.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        FDAttrBar(label: key.capitalized, value: value, color: FDTheme.accentTeal)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
            }
        }
        .fdCardSurface()
    }
}

// MARK: - Parcours Row

private struct FDParcoursRow: View {
    let transfer: FDTransferRecord

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.subheadline)
                .foregroundStyle(FDTheme.accentTeal)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(transfer.clubName).font(FDFont.body(16, black: true))
                Text(transfer.country).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(transfer.age) ans").font(FDFont.mono(16, bold: true)).foregroundStyle(.secondary)
                Text(fdFormatMoney(transfer.fee)).font(.subheadline).foregroundStyle(FDTheme.amber)
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
                .font(FDFont.mono(18, bold: true))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(.system(size: 13, weight: .bold))
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
                                .font(.body)
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
                            .fdCardSurface()
                            .padding(.horizontal, 14)
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    Text("Aucune carrière").foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FDTheme.bg.ignoresSafeArea())
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
                    .font(.system(size: 19))
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("SAISON \(entry.season)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(FDTheme.accentTeal)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(entry.age) ans")
                        .font(FDFont.mono(14))
                        .foregroundStyle(.secondary)
                }
                Text(entry.text)
                    .font(.subheadline)
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
    @State private var showRegles = false

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
                            .font(.subheadline).foregroundStyle(.secondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                    }
                    .fdCardSurface()

                    VStack(spacing: 0) {
                        FDSectionHeader(icon: "xmark.circle.fill", title: "Abandonner", color: FDTheme.destructive)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        FDOptionRow(icon: "trash.fill", label: "Abandonner cette carrière", color: FDTheme.destructive) {
                            showAbandonConfirm = true
                        }
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        Text("La carrière est effacée sans rejoindre ton historique — elle ne rapporte ni points ni pièces.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                    }
                    .fdCardSurface()

                    // The rules live one tap away from the game itself, not only in the menu.
                    Button {
                        FDHaptics.tap()
                        showRegles = true
                    } label: {
                        VStack(spacing: 0) {
                            FDSectionHeader(icon: "book.fill", title: "Règles du jeu", color: FDTheme.primary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                            HStack {
                                Text("Modes de jeu, monnaies, Boutique, Défis et barème du classement.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(FDTheme.primary)
                            }
                            .padding(14)
                        }
                        .fdCardSurface()
                    }
                    .buttonStyle(FDRowButtonStyle())

                    VStack(spacing: 0) {
                        FDSectionHeader(icon: "info.circle.fill", title: "À propos", color: .secondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        Text("FCS-Destiny — aucun compte, aucune inscription. Ta progression est enregistrée automatiquement sur cet appareil et nulle part ailleurs.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .padding(14)
                    }
                    .fdCardSurface()
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FDTheme.bg.ignoresSafeArea())
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
            .sheet(isPresented: $showRegles) { FDReglesView() }
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
                    .font(FDFont.body(18))
                    .foregroundStyle(disabled ? .secondary : FDTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
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


/// One of the four state figures shown above the scene: a big number, its label, and a bar
/// that fills with the value — the player's condition readable without leaving the story.
private struct FDStateChip: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(FDFont.mono(19, bold: true))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .black))
                .tracking(0.4)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.09))
                    Capsule()
                        .fill(color)
                        .frame(width: g.size.width * CGFloat(min(max(value, 0), 100)) / 100)
                        .animation(.fdSoft, value: value)
                }
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(FDTheme.bg.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.22), lineWidth: 1)
        )
    }
}
