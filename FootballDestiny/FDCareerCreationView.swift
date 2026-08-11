import SwiftUI
import Foundation

struct FDClubGroup: Identifiable {
    let id: String
    let clubs: [FDClub]
}

private enum FDCreationStep: Int, CaseIterable {
    case identityNationality, position, background, profile, settings, club
}

struct FDCareerCreationView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen

    @State private var stepIndex = 0
    @State private var draft = FDCreationDraft()
    @State private var clubSearch = ""

    private let steps = FDCreationStep.allCases
    private var currentStep: FDCreationStep { steps[stepIndex] }

    private var identityValid: Bool {
        !draft.firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !draft.lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var showsReroll: Bool {
        switch currentStep {
        case .identityNationality, .position, .background, .profile, .settings: return true
        case .club: return false
        }
    }

    var body: some View {
        NavigationView {
            Group {
                switch currentStep {
                case .identityNationality: identityNationalityStep
                case .position: positionStep
                case .background: backgroundStep
                case .profile: profileStep
                case .settings: settingsStep
                case .club: clubStep
                }
            }
            .background(FDTheme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: goBack) {
                        Image(systemName: stepIndex > 0 ? "chevron.left" : "xmark")
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 5) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Capsule()
                                .fill(i == stepIndex ? FDTheme.primary : (i < stepIndex ? FDTheme.primary.opacity(0.4) : Color.white.opacity(0.18)))
                                .frame(width: i == stepIndex ? 16 : 6, height: 6)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: rerollCurrent) {
                        Image(systemName: "dice.fill")
                            .foregroundStyle(FDTheme.amber)
                    }
                    .opacity(showsReroll ? 1 : 0)
                    .disabled(!showsReroll)
                    .allowsHitTesting(showsReroll)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Navigation

    private func goBack() {
        if stepIndex > 0 {
            withAnimation(.easeInOut(duration: 0.25)) { stepIndex -= 1 }
        } else {
            screen = .menu
        }
    }

    private func advance() {
        if stepIndex < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) { stepIndex += 1 }
        }
    }

    private func selectAndAdvance(_ assign: @escaping () -> Void) {
        FDHaptics.tap()
        assign()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            advance()
        }
    }

    private func rerollCurrent() {
        FDHaptics.tap()
        switch currentStep {
        case .identityNationality: draft.nationality = FDNations.randomElement() ?? draft.nationality
        case .position: draft.position = FDPosition.allCases.randomElement() ?? draft.position
        case .background: draft.background = FDBackground.allCases.randomElement() ?? draft.background
        case .profile:
            draft.foot = FDFoot.allCases.randomElement() ?? draft.foot
            draft.style = FDStyle.allCases.randomElement() ?? draft.style
            draft.personality = FDPersonality.allCases.randomElement() ?? draft.personality
        case .settings:
            draft.difficulty = FDDifficulty.allCases.randomElement() ?? draft.difficulty
        case .club: break
        }
    }

    // MARK: Step 0 — identity + nationality

    private var identityNationalityStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                FDStepHeader(title: "Toi", subtitle: "Ton nom, et le pays qui te verra grandir sur les terrains.")

                VStack(spacing: 10) {
                    TextField("Prénom", text: $draft.firstName).fdField()
                    TextField("Nom", text: $draft.lastName).fdField()
                }
                .fdCard()

                if !identityValid {
                    Text("Renseigne ton prénom et ton nom pour choisir ta nationalité.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(FDNations, id: \.self) { nation in
                        FDFlagCard(flag: fdFlag(for: nation), name: nation, selected: draft.nationality == nation) {
                            selectAndAdvance { draft.nationality = nation }
                        }
                    }
                }
                .disabled(!identityValid)
                .opacity(identityValid ? 1 : 0.35)
            }
            .padding()
        }
    }

    // MARK: Step 1 — position

    private var positionStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                FDStepHeader(title: "Ton poste", subtitle: "Il façonnera tes statistiques, tes évènements et ta légende.")
                VStack(spacing: 12) {
                    ForEach(FDPosition.allCases) { p in
                        FDChoiceCard(icon: p.flavorIcon, title: p.rawValue, subtitle: p.flavorText, selected: draft.position == p) {
                            selectAndAdvance { draft.position = p }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: Step 2 — background

    private var backgroundStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                FDStepHeader(title: "Ton milieu familial", subtitle: "D'où tu viens, avant les projecteurs.")
                VStack(spacing: 12) {
                    ForEach(FDBackground.allCases) { b in
                        FDChoiceCard(icon: b.flavorIcon, title: b.rawValue, subtitle: b.flavorText, selected: draft.background == b) {
                            selectAndAdvance { draft.background = b }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: Step 3 — profile (foot + style + personality)

    private var profileStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                FDStepHeader(title: "Ton profil", subtitle: "Pied fort, style de jeu et personnalité.")

                VStack(alignment: .leading, spacing: 10) {
                    FDSectionLabel("Pied fort")
                    FDChipScrollRow(items: FDFoot.allCases, label: { $0.rawValue }, icon: { $0.flavorIcon }, selection: draft.foot) { f in
                        FDHaptics.tap(); draft.foot = f
                    }
                    Text(draft.foot.flavorText).font(.caption).foregroundStyle(.secondary)
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 10) {
                    FDSectionLabel("Style de jeu")
                    FDChipScrollRow(items: FDStyle.allCases, label: { $0.rawValue }, icon: { $0.flavorIcon }, selection: draft.style) { s in
                        FDHaptics.tap(); draft.style = s
                    }
                    Text(draft.style.flavorText).font(.caption).foregroundStyle(.secondary)
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 10) {
                    FDSectionLabel("Personnalité")
                    FDChipScrollRow(items: FDPersonality.allCases, label: { $0.rawValue }, icon: { $0.flavorIcon }, selection: draft.personality) { p in
                        FDHaptics.tap(); draft.personality = p
                    }
                    Text(draft.personality.flavorText).font(.caption).foregroundStyle(.secondary)
                }
                .fdCard()

                Button {
                    FDHaptics.tap()
                    advance()
                } label: {
                    Text("Continuer")
                }
                .buttonStyle(FDPrimaryButtonStyle())
            }
            .padding()
        }
    }

    // MARK: Step 4 — settings (difficulty + mode)

    private var settingsStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                FDStepHeader(title: "Réglages de carrière", subtitle: "La difficulté, et la manière dont tu veux vivre ton histoire.")

                VStack(alignment: .leading, spacing: 10) {
                    FDSectionLabel("Difficulté")
                    FDChipScrollRow(items: FDDifficulty.allCases, label: { $0.rawValue }, icon: { $0.flavorIcon }, selection: draft.difficulty) { d in
                        FDHaptics.tap(); draft.difficulty = d
                    }
                    Text(draft.difficulty.flavorText).font(.caption).foregroundStyle(.secondary)
                }
                .fdCard()

                VStack(alignment: .leading, spacing: 10) {
                    FDSectionLabel("Style de carrière")
                    FDChipScrollRow(items: FDMode.allCases, label: { $0.rawValue }, icon: { $0.flavorIcon }, selection: draft.mode) { m in
                        FDHaptics.tap(); draft.mode = m
                    }
                    Text(draft.mode.hint).font(.caption).foregroundStyle(.secondary)
                }
                .fdCard()

                if engine.lifetimePoints > 0 {
                    Text("🏆 \(engine.lifetimePoints) points de carrière cumulés : ton potentiel de départ démarre un peu plus haut grâce à ton expérience.")
                        .font(.caption)
                        .foregroundStyle(FDTheme.gold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    FDHaptics.tap()
                    advance()
                } label: {
                    Text("Continuer")
                }
                .buttonStyle(FDPrimaryButtonStyle())
            }
            .padding()
        }
    }

    // MARK: Step 5 — club

    private var filteredClubs: [FDClub] {
        if clubSearch.trimmingCharacters(in: .whitespaces).isEmpty { return FDAllClubs }
        let q = clubSearch.lowercased()
        return FDAllClubs.filter {
            $0.name.lowercased().contains(q) || $0.city.lowercased().contains(q) || $0.country.lowercased().contains(q)
        }
    }

    /// The continent tied to the player's chosen nationality, when at least one club exists there.
    private var homeContinent: String? {
        FDAllClubs.first(where: { $0.country == draft.nationality })?.continent
    }

    private var clubsByContinent: [FDClubGroup] {
        let groups = Dictionary(grouping: filteredClubs, by: { $0.continent })
        var order = ["Europe", "Amérique du Sud", "Amérique du Nord", "Asie", "Afrique", "Océanie"]
        if let home = homeContinent, let idx = order.firstIndex(of: home), idx != 0 {
            order.remove(at: idx)
            order.insert(home, at: 0)
        }
        return order.compactMap { c in
            guard let list = groups[c], !list.isEmpty else { return nil }
            let sorted = list.sorted { a, b in
                let aHome = a.country == draft.nationality
                let bHome = b.country == draft.nationality
                if aHome != bHome { return aHome }
                return a.reputation > b.reputation
            }
            return FDClubGroup(id: c, clubs: sorted)
        }
    }

    private var clubStep: some View {
        VStack(spacing: 0) {
            FDStepHeader(
                title: "Ton club de jeunes",
                subtitle: "Celui qui lancera ta carrière à 15 ans. Les clubs de \(draft.nationality) apparaissent en premier."
            )
            .padding(.bottom, 8)

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

// MARK: - Shared step UI

private struct FDStepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(FDFont.display(26))
                .tracking(-0.5)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(FDFont.body(14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct FDChoiceCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                FDIconBadge(symbol: icon, tint: FDTheme.primary, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(FDFont.display(19))
                    Text(subtitle).font(FDFont.body(13)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(FDTheme.primary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FDTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? FDTheme.primary : Color.white.opacity(0.08), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FDFlagCard: View {
    let flag: String
    let name: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                FDIconBadge(symbol: flag, tint: .white, size: 44)
                Text(name)
                    .font(FDFont.body(14, black: true))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(FDTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? FDTheme.primary : Color.white.opacity(0.08), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Horizontally-scrolling row of selectable pills, used to keep secondary choices
/// (foot, style, personality, difficulty, mode) fast to pick without a full screen each.
private struct FDChipScrollRow<T: Hashable>: View {
    let items: [T]
    let label: (T) -> String
    let icon: (T) -> String
    let selection: T
    let onSelect: (T) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        HStack(spacing: 6) {
                            Text(icon(item))
                            Text(label(item)).font(FDFont.body(14, black: true))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(item == selection ? FDTheme.primary : FDTheme.bg.opacity(0.6))
                        )
                        .foregroundStyle(item == selection ? FDTheme.ink : Color.white.opacity(0.85))
                        .overlay(
                            Capsule().stroke(item == selection ? Color.clear : Color.white.opacity(0.10), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
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
                    Text(club.name).font(FDFont.body(15, black: true))
                    Text("\(club.city), \(club.country)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("D\(club.division)")
                    .font(FDFont.mono(11, bold: true))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(FDTheme.accentTeal.opacity(0.18))
                    .foregroundStyle(FDTheme.accentTeal)
                    .clipShape(Capsule())
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(FDTheme.primary)
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
                .fill(FDTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? FDTheme.primary.opacity(0.6) : Color.white.opacity(0.06), lineWidth: selected ? 1.5 : 1)
        )
    }
}

struct FDMiniStat: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(label) \(value)").font(FDFont.mono(10)).foregroundStyle(.secondary)
            ProgressView(value: Double(value), total: 100)
                .tint(FDTheme.primary)
                .frame(width: 56)
        }
    }
}

// MARK: - Flavor content (own wording, not sourced from any other app)

private func fdFlag(for nation: String) -> String {
    let flags: [String: String] = [
        "France": "🇫🇷", "Angleterre": "🇬🇧", "Espagne": "🇪🇸", "Allemagne": "🇩🇪",
        "Italie": "🇮🇹", "Portugal": "🇵🇹", "Pays-Bas": "🇳🇱", "Belgique": "🇧🇪",
        "Brésil": "🇧🇷", "Argentine": "🇦🇷", "Uruguay": "🇺🇾", "Colombie": "🇨🇴",
        "États-Unis": "🇺🇸", "Canada": "🇨🇦", "Mexique": "🇲🇽", "Sénégal": "🇸🇳",
        "Côte d'Ivoire": "🇨🇮", "Cameroun": "🇨🇲", "Nigeria": "🇳🇬", "Maroc": "🇲🇦",
        "Algérie": "🇩🇿", "Tunisie": "🇹🇳", "Égypte": "🇪🇬", "Japon": "🇯🇵",
        "Corée du Sud": "🇰🇷", "Australie": "🇦🇺", "Émirats Arabes Unis": "🇦🇪",
        "Arabie Saoudite": "🇸🇦", "Turquie": "🇹🇷", "Croatie": "🇭🇷", "Suède": "🇸🇪",
        "Norvège": "🇳🇴", "Danemark": "🇩🇰"
    ]
    return flags[nation] ?? "🏳️"
}

private extension FDPosition {
    var flavorIcon: String {
        switch self {
        case .gardien: return "🧤"
        case .defenseurCentral: return "🛡️"
        case .lateral: return "🏃"
        case .milieuDefensif: return "🧭"
        case .milieuRelayeur: return "🔁"
        case .milieuOffensif: return "🎯"
        case .ailier: return "💨"
        case .avantCentre: return "⚽"
        }
    }
    var flavorText: String {
        switch self {
        case .gardien: return "Le dernier rempart. Un sang-froid d'acier quand tout se joue sur un ballon."
        case .defenseurCentral: return "Le roc de la défense. Par ici, on ne passe pas."
        case .lateral: return "Les couloirs sont à toi, entre courses défensives et centres décisifs."
        case .milieuDefensif: return "L'équilibre de l'équipe repose sur tes épaules, discret mais indispensable."
        case .milieuRelayeur: return "Le lien entre défense et attaque, celui qui fait tourner le jeu."
        case .milieuOffensif: return "Le dernier geste avant le but, celui qui invente le jeu."
        case .ailier: return "Vitesse et dribbles, la terreur des défenses sur les côtés."
        case .avantCentre: return "Le finisseur. Ton nom s'écrit dans la feuille de match à coups de buts."
        }
    }
}

private extension FDFoot {
    var flavorIcon: String {
        switch self {
        case .droit: return "🦵"
        case .gauche: return "🦶"
        case .ambidextre: return "🔀"
        }
    }
    var flavorText: String {
        switch self {
        case .droit: return "Pied droit, ton arme naturelle pour percuter et frapper."
        case .gauche: return "Pied gauche, rare et précieux sur un terrain."
        case .ambidextre: return "Les deux pieds à l'aise — un atout que peu de joueurs possèdent."
        }
    }
}

private extension FDStyle {
    var flavorIcon: String {
        switch self {
        case .technicien: return "🎩"
        case .rapide: return "💨"
        case .puissant: return "💪"
        case .createur: return "🎨"
        case .finisseur: return "🎯"
        case .recuperateur: return "🧹"
        case .leader: return "📣"
        }
    }
    var flavorText: String {
        switch self {
        case .technicien: return "Un ballon collé au pied, la technique avant tout."
        case .rapide: return "Personne ne te rattrape sur les trente derniers mètres."
        case .puissant: return "Impossible à bouger, un rapport de force toujours à ton avantage."
        case .createur: return "Tu vois la passe avant même que les autres ne l'imaginent."
        case .finisseur: return "Une occasion, un but. Voilà ta réputation qui se construit."
        case .recuperateur: return "Le ballon te revient toujours, par n'importe quel moyen nécessaire."
        case .leader: return "Le vestiaire t'écoute, le terrain te suit."
        }
    }
}

private extension FDPersonality {
    var flavorIcon: String {
        switch self {
        case .ambitieux: return "🔥"
        case .discipline: return "📋"
        case .charismatique: return "✨"
        case .reserve: return "🤫"
        case .provocateur: return "😈"
        case .travailleur: return "⚒️"
        case .irregulier: return "🎢"
        }
    }
    var flavorText: String {
        switch self {
        case .ambitieux: return "Rien ne t'arrête, chaque saison doit dépasser la précédente."
        case .discipline: return "Rigueur et sérieux, tu ne laisses rien au hasard."
        case .charismatique: return "Les projecteurs t'aiment, et toi aussi."
        case .reserve: return "Tu laisses parler ton jeu plutôt que les mots."
        case .provocateur: return "Chambreur sur le terrain, tu adores jouer avec les nerfs adverses."
        case .travailleur: return "Le talent ne suffit pas, tu travailles plus dur que les autres."
        case .irregulier: return "Des étincelles de génie, et des soirs sans éclat. Un pari à chaque match."
        }
    }
}

private extension FDBackground {
    var flavorIcon: String {
        switch self {
        case .modeste: return "🏠"
        case .stable: return "⚖️"
        case .aisee: return "💼"
        case .footballeur: return "👨‍👦"
        }
    }
    var flavorText: String {
        switch self {
        case .modeste: return "Rien n'a été donné, tout a été gagné à la sueur."
        case .stable: return "Un cadre solide, ni trop dur ni trop facile, pour grandir sereinement."
        case .aisee: return "Les meilleures conditions dès le départ, mais des attentes à la hauteur."
        case .footballeur: return "Le foot coule dans tes veines. Un nom à porter, une légende à égaler."
        }
    }
}

private extension FDDifficulty {
    var flavorIcon: String {
        switch self {
        case .facile: return "🌤️"
        case .normal: return "⚖️"
        case .difficile: return "⛈️"
        }
    }
    var flavorText: String {
        switch self {
        case .facile: return "Une carrière plus clémente, pour profiter de l'histoire sans trop de pression."
        case .normal: return "L'expérience équilibrée, entre défis réalistes et progression juste."
        case .difficile: return "Chaque détail compte. Une carrière exigeante, réservée aux plus courageux."
        }
    }
}

private extension FDMode {
    var flavorIcon: String {
        switch self {
        case .narratif: return "📖"
        case .express: return "⏩"
        }
    }
}
