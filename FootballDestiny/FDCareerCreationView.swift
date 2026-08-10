import SwiftUI
import Foundation

struct FDClubGroup: Identifiable {
    let id: String
    let clubs: [FDClub]
}

struct FDCareerCreationView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen

    @State private var step = 1
    @State private var draft = FDCreationDraft()
    @State private var clubSearch = ""

    private var identityValid: Bool {
        !draft.firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !draft.lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Group {
                switch step {
                case 1: identityStep
                case 2: profileStep
                default: clubStep
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nouvelle carrière")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if step > 1 { step -= 1 } else { screen = .menu }
                    } label: {
                        Image(systemName: step > 1 ? "chevron.left" : "xmark")
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 5) {
                        ForEach(1...3, id: \.self) { i in
                            Circle()
                                .fill(i <= step ? FDTheme.gold : Color(.systemGray4))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Step 1 — identity

    private var identityStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    FDSectionLabel("Identité")
                    TextField("Prénom", text: $draft.firstName)
                        .fdField()
                    TextField("Nom", text: $draft.lastName)
                        .fdField()
                    Picker("Nationalité", selection: $draft.nationality) {
                        ForEach(FDNations, id: \.self) { nation in Text(nation).tag(nation) }
                    }
                    .pickerStyle(.menu)
                    .fdField()
                    TextField("Ville natale", text: $draft.birthCity)
                        .fdField()
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 12) {
                    FDSectionLabel("Milieu familial")
                    Picker("Milieu familial", selection: $draft.background) {
                        ForEach(FDBackground.allCases) { b in Text(b.rawValue).tag(b) }
                    }
                    .pickerStyle(.menu)
                    .fdField()
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 12) {
                    FDSectionLabel("Difficulté")
                    Picker("Difficulté", selection: $draft.difficulty) {
                        ForEach(FDDifficulty.allCases) { d in Text(d.rawValue).tag(d) }
                    }
                    .pickerStyle(.segmented)
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 10) {
                    FDSectionLabel("Style de carrière")
                    Picker("Style de carrière", selection: $draft.mode) {
                        ForEach(FDMode.allCases) { m in Text(m.rawValue).tag(m) }
                    }
                    .pickerStyle(.segmented)
                    Text(draft.mode.hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .fdCard()

                Button {
                    FDHaptics.tap()
                    step = 2
                } label: {
                    Text("Suivant")
                }
                .buttonStyle(FDPrimaryButtonStyle())
                .disabled(!identityValid)
                .opacity(identityValid ? 1 : 0.5)
            }
            .padding()
        }
    }

    // MARK: Step 2 — position, foot, style, personality

    private var profileStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    FDSectionLabel("Poste principal")
                    Picker("Poste", selection: $draft.position) {
                        ForEach(FDPosition.allCases) { p in Text(p.rawValue).tag(p) }
                    }
                    .pickerStyle(.menu)
                    .fdField()
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 12) {
                    FDSectionLabel("Pied fort")
                    Picker("Pied fort", selection: $draft.foot) {
                        ForEach(FDFoot.allCases) { f in Text(f.rawValue).tag(f) }
                    }
                    .pickerStyle(.segmented)
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 12) {
                    FDSectionLabel("Style de jeu")
                    Picker("Style de jeu", selection: $draft.style) {
                        ForEach(FDStyle.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                    .pickerStyle(.menu)
                    .fdField()
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 12) {
                    FDSectionLabel("Personnalité")
                    Picker("Personnalité", selection: $draft.personality) {
                        ForEach(FDPersonality.allCases) { p in Text(p.rawValue).tag(p) }
                    }
                    .pickerStyle(.menu)
                    .fdField()
                }
                .fdCard()

                Button {
                    FDHaptics.tap()
                    step = 3
                } label: {
                    Text("Choisir un club")
                }
                .buttonStyle(FDPrimaryButtonStyle())
            }
            .padding()
        }
    }

    // MARK: Step 3 — club

    private var filteredClubs: [FDClub] {
        if clubSearch.trimmingCharacters(in: .whitespaces).isEmpty { return FDAllClubs }
        let q = clubSearch.lowercased()
        return FDAllClubs.filter {
            $0.name.lowercased().contains(q) || $0.city.lowercased().contains(q) || $0.country.lowercased().contains(q)
        }
    }

    private var clubsByContinent: [FDClubGroup] {
        let groups = Dictionary(grouping: filteredClubs, by: { $0.continent })
        let order = ["Europe", "Amérique du Sud", "Amérique du Nord", "Asie", "Afrique", "Océanie"]
        return order.compactMap { c in
            guard let list = groups[c], !list.isEmpty else { return nil }
            return FDClubGroup(id: c, clubs: list.sorted { $0.reputation > $1.reputation })
        }
    }

    private var clubStep: some View {
        VStack(spacing: 0) {
            Text("Choisis le club de jeunes qui lancera ta carrière à 15 ans.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 4)

            List {
                ForEach(clubsByContinent) { group in
                    Section(header: Text(group.id).font(.caption.weight(.bold))) {
                        ForEach(group.clubs) { club in
                            FDClubRow(club: club, selected: draft.club?.id == club.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    FDHaptics.tap()
                                    draft.club = club
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $clubSearch, prompt: "Rechercher un club, une ville…")

            Button {
                guard let club = draft.club else { return }
                FDHaptics.success()
                engine.startCareer(draft: draft, club: club)
                screen = .game
            } label: {
                Text("Démarrer la carrière")
            }
            .buttonStyle(FDPrimaryButtonStyle())
            .disabled(draft.club == nil)
            .opacity(draft.club == nil ? 0.5 : 1)
            .padding()
        }
    }
}

struct FDClubRow: View {
    let club: FDClub
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(club.name).font(.subheadline.weight(.semibold))
                    Text("\(club.city), \(club.country)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("D\(club.division)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
            HStack(spacing: 14) {
                FDMiniStat(label: "Réputation", value: club.reputation)
                FDMiniStat(label: "Formation", value: club.academyQuality)
                FDMiniStat(label: "Jeu jeunes", value: club.youthMinutes)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.05), lineWidth: selected ? 1.5 : 1)
        )
    }
}

struct FDMiniStat: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(label) \(value)").font(.caption2).foregroundStyle(.secondary)
            ProgressView(value: Double(value), total: 100)
                .frame(width: 56)
        }
    }
}
