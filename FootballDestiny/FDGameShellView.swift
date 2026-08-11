import SwiftUI
import UIKit
import Foundation

struct FDGameShellView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FDHistoireTab(engine: engine)
                .tabItem { Label("Histoire", systemImage: "sportscourt.fill") }
                .tag(0)
            FDCarriereTab(engine: engine)
                .tabItem { Label("Carrière", systemImage: "star.fill") }
                .tag(1)
            FDStatsTab(engine: engine)
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(2)
            FDJournalTab(engine: engine)
                .tabItem { Label("Journal", systemImage: "newspaper.fill") }
                .tag(3)
            FDOptionsTab(engine: engine, screen: $screen)
                .tabItem { Label("Options", systemImage: "gearshape.fill") }
                .tag(4)
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

// MARK: - Status header

struct FDStatusHeader: View {
    @ObservedObject var engine: FDGameEngine

    var body: some View {
        if let p = engine.player {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    FDLogoBadge(size: 26, corner: 7)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(p.firstName) \(p.lastName)").font(FDFont.body(14, black: true))
                        Text("\(p.club.name) · \(p.position.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Label(fdFormatMoney(p.money), systemImage: "eurosign.circle.fill")
                            .foregroundStyle(FDTheme.amber)
                        Label("\(p.cond.forme)", systemImage: "waveform.path.ecg")
                            .foregroundStyle(FDTheme.primary)
                    }
                    .font(FDFont.mono(12, bold: true))
                }
                ProgressView(value: Double(p.calendar.week), total: Double(p.calendar.seasonWeeks))
                    .tint(FDTheme.primary)
                HStack {
                    Text("Saison \(p.calendar.season) · \(p.age) ans · \(p.status.rawValue)")
                    Spacer()
                    Text("⭐ Réputation \(p.cond.reputation)")
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(.thinMaterial)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1)
            }
        }
    }
}

struct FDToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(FDTheme.gold.opacity(0.4), lineWidth: 1))
            .shadow(radius: 8)
            .padding(.horizontal, 24)
    }
}

// MARK: - Histoire tab

struct FDHistoireTab: View {
    @ObservedObject var engine: FDGameEngine

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let p = engine.player, p.retired {
                        FDRetiredCard(engine: engine)
                    } else {
                        switch engine.currentScene {
                        case .none:
                            ProgressView().padding(.top, 60)
                        case .story(let scene):
                            FDStoryCard(engine: engine, scene: scene)
                        case .match(let result):
                            FDMatchCard(engine: engine, result: result)
                        case .season(let lines):
                            FDSeasonCard(engine: engine, lines: lines)
                        }
                    }
                }
                .padding()
            }
            .background(FDTheme.bg)
            .navigationTitle("Histoire")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
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
    default: return FDTheme.accentTeal
    }
}

struct FDCardVisual: View {
    let symbol: String
    let color: Color
    let loc: String
    let char: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [color, color.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: symbol)
                .font(.system(size: 26))
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .padding(14)
            VStack(alignment: .leading, spacing: 1) {
                Text(loc.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.85))
                Text(char).font(.headline).foregroundStyle(.white)
            }
            .padding(14)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct FDStoryCard: View {
    @ObservedObject var engine: FDGameEngine
    let scene: FDSceneDef

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FDCardVisual(symbol: fdSceneSymbol(scene.category), color: fdSceneColor(scene.category), loc: scene.location, char: scene.character)
            Text(scene.category.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(FDTheme.accentTeal)
            Text(scene.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 9) {
                ForEach(Array(scene.choices.enumerated()), id: \.offset) { _, choice in
                    Button {
                        FDHaptics.tap()
                        engine.resolveChoice(choice)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(choice.label).font(.subheadline.weight(.semibold))
                            if !choice.hint.isEmpty {
                                Text(choice.hint).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .fdCard()
    }
}

struct FDMatchCard: View {
    @ObservedObject var engine: FDGameEngine
    let result: FDMatchResult

    private var narrative: String {
        var lines: [String] = []
        if result.minutes == 0 { lines.append("Tu n'as pas été retenu dans le groupe pour ce match.") }
        else if !result.started { lines.append("Entré en jeu à la \(90 - result.minutes)e minute.") }
        else { lines.append("Titulaire dès le coup d'envoi.") }
        if result.goals > 0 { lines.append(result.goals > 1 ? "Doublé ! \(result.goals) buts inscrits." : "Un but inscrit !") }
        if result.assists > 0 { lines.append("\(result.assists) passe(s) décisive(s).") }
        if result.red { lines.append("Exclusion après un second avertissement.") }
        else if result.yellow { lines.append("Carton jaune reçu.") }
        if result.injury { lines.append("Une gêne physique t'a contraint à ralentir.") }
        return lines.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FDCardVisual(symbol: "soccerball", color: .green, loc: "Jour de match", char: engine.player?.club.name ?? "")
            VStack(spacing: 4) {
                Text("\(result.teamScore) - \(result.oppScore)")
                    .font(FDFont.mono(34, bold: true))
                HStack {
                    Text(engine.player?.club.name ?? "")
                    Spacer()
                    Text("Adversaire (niv. \(result.opponentLevel))")
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            Text(narrative).font(.subheadline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                FDMatchStat(value: "\(result.minutes)'", label: "Minutes")
                FDMatchStat(value: result.minutes > 0 ? String(format: "%.1f", result.rating) : "—", label: "Note")
                FDMatchStat(value: "\(result.goals)", label: "Buts")
                FDMatchStat(value: "\(result.assists)", label: "Passes D.")
            }
            Button {
                FDHaptics.tap()
                engine.advanceWeek()
            } label: {
                Text("Continuer")
            }
            .buttonStyle(FDPrimaryButtonStyle())
        }
        .fdCard()
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

struct FDSeasonCard: View {
    @ObservedObject var engine: FDGameEngine
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FDCardVisual(symbol: "trophy.fill", color: FDTheme.amber, loc: "Bilan de saison", char: "Saison \((engine.player?.calendar.season ?? 1) - 1)")
            Text("RÉSUMÉ").font(.caption2.weight(.bold)).foregroundStyle(FDTheme.accentTeal)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(lines, id: \.self) { Text($0).font(.subheadline) }
            }
            Button {
                FDHaptics.tap()
                engine.continueAfterSeason()
            } label: {
                Text(engine.player?.retired == true ? "Voir le résumé" : "Nouvelle saison")
            }
            .buttonStyle(FDPrimaryButtonStyle())
        }
        .fdCard()
    }
}

struct FDRetiredCard: View {
    @ObservedObject var engine: FDGameEngine

    var body: some View {
        if let p = engine.player {
            VStack(alignment: .leading, spacing: 14) {
                FDCardVisual(symbol: "sunset.fill", color: .orange, loc: "Fin de carrière", char: "\(p.firstName) \(p.lastName)")
                Text("Après \(max(0, p.calendar.season - 1)) saison(s) de carrière, tout s'arrête à \(p.age) ans. \(p.careerApps) matchs joués, \(p.careerGoals) buts, \(p.careerAssists) passes décisives. Merci d'avoir vécu cette légende.")
                    .font(.subheadline)
                Button {
                    engine.resetSave()
                } label: {
                    Text("Commencer une nouvelle carrière")
                }
                .buttonStyle(FDPrimaryButtonStyle())
            }
            .fdCard()
        }
    }
}

// MARK: - Carrière tab

struct FDCarriereTab: View {
    @ObservedObject var engine: FDGameEngine

    var body: some View {
        NavigationView {
            if let p = engine.player {
                List {
                    Section {
                        VStack(spacing: 14) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(p.firstName) \(p.lastName)").font(.title3.weight(.bold))
                                    Text("\(p.nationality) · \(p.age) ans · \(p.position.rawValue)").font(.caption).foregroundStyle(.secondary)
                                    Text("\(p.club.name) (\(p.club.city), \(p.club.country))").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack {
                                    Text("\(engine.overall(p))").font(FDFont.mono(20, bold: true)).foregroundStyle(FDTheme.primary)
                                    Text("NOTE").font(.caption2.weight(.bold)).foregroundStyle(FDTheme.primary)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(FDTheme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                            }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                FDMetaTile(value: "\(engine.potentialOverall(p))", label: "Potentiel")
                                FDMetaTile(value: fdFormatMoney(engine.marketValue(p)), label: "Valeur")
                                FDMetaTile(value: fdFormatMoney(p.contract.salary), label: "Salaire/sem")
                                FDMetaTile(value: p.status.rawValue, label: "Statut")
                                FDMetaTile(value: p.style.rawValue, label: "Style")
                                FDMetaTile(value: p.mode.rawValue, label: "Mode")
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    Section("Condition") {
                        FDConditionRow(label: "Forme", value: p.cond.forme, color: FDTheme.primary)
                        FDConditionRow(label: "Moral", value: p.cond.moral, color: .blue)
                        FDConditionRow(label: "Fatigue", value: p.cond.fatigue, color: .orange)
                        FDConditionRow(label: "Confiance", value: p.cond.confiance, color: FDTheme.accentTeal)
                    }

                    ForEach([FDAttrCategory.tech, .phys, .ment, .def], id: \.self) { cat in
                        Section("Attributs — \(cat.label)") {
                            ForEach(FDAttribute.allCases.filter { $0.category == cat }, id: \.self) { attr in
                                FDAttributeRow(label: attr.label, value: p.attr(attr))
                            }
                        }
                    }

                    Section("Relations") {
                        FDConditionRow(label: "Entraîneur", value: p.rel.coach, color: FDTheme.accentTeal)
                        FDConditionRow(label: "Président", value: p.rel.president, color: FDTheme.accentTeal)
                        FDConditionRow(label: "Vestiaire", value: p.rel.vestiaire, color: FDTheme.primary)
                        FDConditionRow(label: "Capitaine", value: p.rel.capitaine, color: FDTheme.primary)
                        FDConditionRow(label: "Famille", value: p.rel.famille, color: .pink)
                        FDConditionRow(label: "Agent", value: p.rel.agent, color: .purple)
                        FDConditionRow(label: "Média", value: p.rel.media, color: .purple)
                        FDConditionRow(label: "Supporters", value: p.rel.fans, color: FDTheme.amber)
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Carrière")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Aucune carrière en cours").foregroundStyle(.secondary)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct FDMetaTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
            Text(label.uppercased()).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct FDConditionRow: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            ProgressView(value: Double(value), total: 100).tint(color).frame(width: 100)
            Text("\(value)").font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 26, alignment: .trailing)
        }
    }
}

struct FDAttributeRow: View {
    let label: String
    let value: Int
    var body: some View {
        HStack {
            Text(label).font(.subheadline).frame(width: 100, alignment: .leading)
            ProgressView(value: Double(value), total: 100)
            Text("\(value)").font(.caption.weight(.semibold).monospacedDigit()).frame(width: 26, alignment: .trailing)
        }
    }
}

// MARK: - Stats tab

struct FDStatsTab: View {
    @ObservedObject var engine: FDGameEngine

    var body: some View {
        NavigationView {
            if let p = engine.player {
                List {
                    Section {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            FDStatTile(value: "\(p.careerApps)", label: "Matchs joués")
                            FDStatTile(value: "\(p.careerGoals)", label: "Buts carrière")
                            FDStatTile(value: "\(p.careerAssists)", label: "Passes décisives")
                            FDStatTile(value: p.history.isEmpty ? "—" : String(format: "%.1f", p.history.map(\.avgRating).reduce(0, +) / Double(p.history.count)), label: "Note moy. carrière")
                        }
                        .padding(.vertical, 4)
                    }

                    if !p.history.isEmpty {
                        Section("Historique des saisons") {
                            ForEach(p.history) { h in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Saison \(h.season) · \(h.age) ans").font(.subheadline.weight(.semibold))
                                        Text(h.status.rawValue).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("\(h.apps) MJ · \(h.goals) B · \(h.assists) PD").font(.caption)
                                        Text(h.avgRating > 0 ? String(format: "Note %.1f", h.avgRating) : "—").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        Section {
                            Text("Ta première saison est en cours — reviens ici après quelques matchs.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Stats")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct FDStatTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(FDFont.mono(19, bold: true))
            Text(label.uppercased()).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Journal tab

struct FDJournalTab: View {
    @ObservedObject var engine: FDGameEngine

    var body: some View {
        NavigationView {
            if let p = engine.player {
                if p.journal.isEmpty {
                    Text("Ton journal de carrière est vide pour l'instant.")
                        .foregroundStyle(.secondary)
                        .navigationTitle("Journal")
                } else {
                    List(p.journal.prefix(150)) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Text(entry.icon).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("S\(entry.season) · \(entry.age) ans").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                                Text(entry.text).font(.subheadline)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("Journal")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Options tab

struct FDOptionsTab: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen
    @State private var showExport = false
    @State private var showImport = false
    @State private var exportText = ""
    @State private var importText = ""
    @State private var showRetireConfirm = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Ta carrière est enregistrée automatiquement sur cet appareil, sans compte ni inscription.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Exporter la sauvegarde") {
                        exportText = engine.exportSave() ?? ""
                        showExport = true
                    }
                    Button("Importer une sauvegarde") {
                        importText = ""
                        showImport = true
                    }
                } header: { Text("Sauvegarde") }

                Section {
                    Button(role: .destructive) {
                        showRetireConfirm = true
                    } label: {
                        Text("Prendre sa retraite maintenant")
                    }
                    .disabled(engine.player?.retired ?? true)
                } header: { Text("Retraite") } footer: { Text("Tu peux mettre fin à ta carrière quand tu le souhaites, à n'importe quel âge.") }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("Réinitialiser la carrière")
                    }
                } header: { Text("Nouvelle carrière") } footer: { Text("Cela effacera définitivement la carrière actuelle sur cet appareil.") }

                Section {
                    Text("FCS-Destiny — prototype natif. Aucune donnée n'est envoyée sur un serveur.")
                        .font(.footnote).foregroundStyle(.secondary)
                } header: { Text("À propos") }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Prendre ta retraite maintenant ?", isPresented: $showRetireConfirm, titleVisibility: .visible) {
                Button("Confirmer la retraite", role: .destructive) {
                    engine.voluntaryRetire()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action est définitive pour cette carrière.")
            }
            .confirmationDialog("Effacer définitivement cette carrière ?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Effacer la carrière", role: .destructive) {
                    engine.resetSave()
                    screen = .menu
                }
                Button("Annuler", role: .cancel) {}
            }
            .sheet(isPresented: $showExport) {
                NavigationView {
                    ScrollView {
                        Text(exportText)
                            .font(FDFont.mono(10))
                            .textSelection(.enabled)
                            .padding()
                    }
                    .navigationTitle("Exporter")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Copier") {
                                UIPasteboard.general.string = exportText
                                FDHaptics.success()
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") { showExport = false }
                        }
                    }
                }
                .navigationViewStyle(.stack)
            }
            .sheet(isPresented: $showImport) {
                NavigationView {
                    VStack {
                        TextEditor(text: $importText)
                            .font(FDFont.mono(11))
                            .padding(8)
                            .background(FDTheme.bg.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                        Text("Colle ici le texte de sauvegarde exporté.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .navigationTitle("Importer")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Importer") {
                                if engine.importSave(importText) { showImport = false }
                            }
                            .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Annuler") { showImport = false }
                        }
                    }
                }
                .navigationViewStyle(.stack)
            }
        }
        .navigationViewStyle(.stack)
    }
}
