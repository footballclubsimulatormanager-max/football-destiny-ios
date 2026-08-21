import SwiftUI
import Foundation

private enum FDCreationStep: Int, CaseIterable {
    case identityNationality, position, background, profile, settings, club
}

struct FDCareerCreationView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen

    @State private var stepIndex = 0
    @State private var stepGoingForward = true
    @State private var draft: FDCreationDraft

    init(engine: FDGameEngine, screen: Binding<FDScreen>) {
        self.engine = engine
        self._screen = screen
        var initialDraft = FDCreationDraft()
        let identity = FDNameBank.identity(for: initialDraft.nationality)
        initialDraft.firstName = identity.first
        initialDraft.lastName = identity.last
        initialDraft.birthCity = identity.city
        initialDraft.foot = FDCareerCreationView.rolledFoot()
        self._draft = State(initialValue: initialDraft)
    }

    /// The settings step now carries the player card — a recap of everything chosen so far —
    /// so it always has something to show, even on a fresh install where no potential star
    /// is affordable and no competence is owned.
    private var steps: [FDCreationStep] { FDCreationStep.allCases }

    private var currentStep: FDCreationStep { steps[min(stepIndex, steps.count - 1)] }

    /// 1-based position of a step in the flow actually being shown.
    private func stepNumber(_ step: FDCreationStep) -> Int {
        (steps.firstIndex(of: step) ?? 0) + 1
    }

    private var showsReroll: Bool {
        switch currentStep {
        case .identityNationality, .position, .background, .profile: return true
        case .settings, .club: return false
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
            .id(currentStep)
            .transition(.fdSlide(forward: stepGoingForward))
            .background(FDTheme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: goBack) {
                        Image(systemName: stepIndex > 0 ? "chevron.left" : "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(FDTheme.primary)
                }
                ToolbarItem(placement: .principal) {
                    // Segmented progress dots
                    HStack(spacing: 4) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Capsule()
                                .fill(i == stepIndex
                                      ? FDTheme.primary
                                      : (i < stepIndex ? FDTheme.primary.opacity(0.5) : Color.white.opacity(0.15)))
                                .frame(width: i == stepIndex ? 20 : 6, height: 5)
                                .animation(.spring(response: 0.3), value: stepIndex)
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
            stepGoingForward = false
            withAnimation(.fdSoft) { stepIndex -= 1 }
        } else {
            screen = .menu
        }
    }

    private func advance() {
        if stepIndex < steps.count - 1 {
            stepGoingForward = true
            withAnimation(.fdSoft) { stepIndex += 1 }
        }
    }

    private func selectAndAdvance(_ assign: @escaping () -> Void) {
        FDHaptics.tap()
        assign()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            advance()
        }
    }

    @ViewBuilder
    private func stickyFooter(title: String, icon: String? = nil, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                if let icon {
                    Image(systemName: icon).font(.body.weight(.bold))
                }
            }
        }
        .buttonStyle(FDPrimaryButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }
        )
    }

    private func rerollCurrent() {
        FDHaptics.tap()
        switch currentStep {
        case .identityNationality:
            rollFullIdentity()
        case .position: draft.position = FDPosition.allCases.randomElement() ?? draft.position
        case .background: draft.background = FDBackground.allCases.randomElement() ?? draft.background
        case .profile:
            draft.personality = FDPersonality.allCases.randomElement() ?? draft.personality
            draft.style = FDStyle.allCases.randomElement() ?? draft.style
        case .settings, .club: break
        }
    }

    /// Re-rolls name and birth city for the nationality already chosen — used when the
    /// player picks a country from the flag grid.
    private func regenerateIdentity() {
        let identity = FDNameBank.identity(for: draft.nationality)
        draft.firstName = identity.first
        draft.lastName = identity.last
        draft.birthCity = identity.city
    }

    /// Rolls the whole identity at once, nationality included, so the country, the name and
    /// the birth city always belong together.
    private func rollFullIdentity() {
        let identity = FDNameBank.randomIdentity()
        draft.nationality = identity.nationality
        draft.firstName = identity.first
        draft.lastName = identity.last
        draft.birthCity = identity.city
        draft.foot = FDCareerCreationView.rolledFoot()
    }

    /// The strong foot is dealt with the rest of the identity rather than picked: roughly
    /// three players in four are right-footed, and true ambidexterity stays rare.
    static func rolledFoot() -> FDFoot {
        switch Int.random(in: 0..<100) {
        case ..<72: return .droit
        case ..<95: return .gauche
        default: return .ambidextre
        }
    }

    // MARK: - Step 1: Identity & Nationality

    private var identityNationalityStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    // Step header
                    FDCreationStepHeader(
                        step: stepNumber(.identityNationality), of: steps.count,
                        icon: "person.fill",
                        title: "Identité",
                        subtitle: "Qui es-tu ?"
                    )

                    // Generated identity — the player never types a name. Both the name and
                    // the birth city follow the selected nationality and are re-rolled with
                    // it, or on demand with the dice below.
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "person.text.rectangle.fill", title: "Ton identité")

                        HStack(spacing: 12) {
                            Text(fdFlag(for: draft.nationality))
                                .font(.system(size: 34))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(draft.firstName) \(draft.lastName)")
                                    .font(FDFont.display(22))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("Né à \(draft.birthCity), \(draft.nationality)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                // The strong foot is dealt, not chosen — shown here so the
                                // player still knows what they were given.
                                HStack(spacing: 4) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Pied \(draft.foot.rawValue.lowercased())")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(FDTheme.accentTeal)
                            }

                            Spacer(minLength: 0)

                            Button {
                                FDHaptics.tap()
                                withAnimation(.fdSnap) { rollFullIdentity() }
                            } label: {
                                Image(systemName: "dice.fill")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(FDTheme.amber)
                                    .frame(width: 38, height: 38)
                                    .background(FDTheme.amber.opacity(0.14), in: Circle())
                            }
                            .buttonStyle(FDChoiceButtonStyle())
                        }
                        .padding(11)
                    }
                    .fdCardSurface()

                    // Nationality — big flags filling each cell, not a text list
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "globe.europe.africa.fill", title: "Nationalité")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(FDNations, id: \.self) { nation in
                                FDFlagChoice(flag: fdFlag(for: nation), name: nation, selected: draft.nationality == nation) {
                                    FDHaptics.tap()
                                    draft.nationality = nation
                                    regenerateIdentity()
                                }
                            }
                        }
                        .padding(11)
                    }
                    .fdCardSurface()

                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            stickyFooter(
                title: "Continuer →",
                enabled: !draft.firstName.isEmpty && !draft.lastName.isEmpty
            ) { advance() }
        }
    }

    // MARK: - Step 2: Position

    private var positionStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    FDCreationStepHeader(
                        step: stepNumber(.position), of: steps.count,
                        icon: "figure.soccer",
                        title: "Poste",
                        subtitle: "Où évolues-tu ?"
                    )

                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "figure.soccer", title: "Position sur le terrain")

                        ForEach(FDPosition.allCases) { position in
                            FDPositionRow(position: position, selected: draft.position == position) {
                                selectAndAdvance { draft.position = position }
                            }
                            if position != FDPosition.allCases.last {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .fdCardSurface()
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Step 3: Background

    private var backgroundStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    FDCreationStepHeader(
                        step: stepNumber(.background), of: steps.count,
                        icon: "house.fill",
                        title: "Origine",
                        subtitle: "D'où viens-tu ?"
                    )

                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "house.fill", title: "Milieu familial")

                        ForEach(FDBackground.allCases, id: \.self) { bg in
                            FDProfileChoiceRow(
                                icon: bg.flavorIcon, title: bg.rawValue, subtitle: bg.flavorText,
                                selected: draft.background == bg, showChevronWhenUnselected: true
                            ) {
                                selectAndAdvance { draft.background = bg }
                            }
                            if bg != FDBackground.allCases.last {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .fdCardSurface()
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Step 4: Profile (personnalité + style)

    private var profileStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    FDCreationStepHeader(
                        step: stepNumber(.profile), of: steps.count,
                        icon: "person.crop.circle.fill.badge.checkmark",
                        title: "Profil",
                        subtitle: "Quel joueur es-tu ?"
                    )

                    // Personnalité — a 2-column tile grid rather than 7 stacked description
                    // rows, so both this and the style picker fit on one screen. The chosen
                    // tile's flavour text is spelled out once underneath instead of repeated
                    // on every option.
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "brain.fill", title: "Personnalité")

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                            ForEach(FDPersonality.allCases, id: \.self) { personality in
                                FDProfileTile(
                                    icon: personality.flavorIcon,
                                    title: personality.rawValue,
                                    selected: draft.personality == personality
                                ) {
                                    FDHaptics.tap()
                                    draft.personality = personality
                                }
                            }
                        }
                        .padding(12)

                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        Text(draft.personality.flavorText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                    }
                    .fdCardSurface()

                    // Style de jeu
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "figure.run", title: "Style de jeu")

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                            ForEach(FDStyle.allCases, id: \.self) { style in
                                FDProfileTile(
                                    icon: style.flavorIcon,
                                    title: style.rawValue,
                                    selected: draft.style == style,
                                    accent: FDTheme.accentTeal
                                ) {
                                    FDHaptics.tap()
                                    draft.style = style
                                }
                            }
                        }
                        .padding(12)

                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        Text(draft.style.flavorText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                    }
                    .fdCardSurface()
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            stickyFooter(title: "Continuer →", enabled: true) { advance() }
        }
    }

    // MARK: - Step 5: Settings (difficulté, mode, potentiel)

    private var settingsStep: some View {
        let maxAffordable = FDPotentialShop.maxAffordableHalfStars(points: engine.lifetimePoints)
        let halfStars = draft.potentialHalfStars
        let bought = max(0, halfStars - FDPotentialShop.freeHalfStars)
        let handicap = max(0, FDPotentialShop.freeHalfStars - halfStars)
        let cost = FDPotentialShop.cumulativeCost(halfStars: bought)
        let available = engine.equippableCompetences

        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    FDCreationStepHeader(
                        step: stepNumber(.settings), of: steps.count,
                        icon: "person.text.rectangle.fill",
                        title: "Ta fiche",
                        subtitle: "Tout ce que tu as choisi, et le potentiel que tes points t'offrent."
                    )

                    // Potential comes first: it is the only thing still changeable here.
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "crown.fill", title: "Potentiel de départ")

                        VStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill").font(.subheadline)
                                Text("\(engine.lifetimePoints) points de carrière cumulés")
                                    .font(FDFont.body(17))
                                Spacer()
                            }
                            .foregroundStyle(FDTheme.amber)

                            // Deux étoiles sont le point de départ, pas un plancher : les
                            // points montent le curseur, et on peut aussi le descendre —
                            // jusqu'à zéro — pour une carrière qui ne pardonne rien. Le jeu
                            // compte en demi-étoiles ici comme partout ailleurs.
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill").font(.subheadline)
                                Text("\(FDPotentialShop.freeStars) étoiles au départ — à toi de monter ou de descendre")
                                    .font(FDFont.body(16))
                                Spacer()
                            }
                            .foregroundStyle(handicap > 0 ? FDTheme.destructive
                                             : (bought > 0 ? FDTheme.amber : FDTheme.success))

                            HStack(spacing: 8) {
                                Button {
                                    guard halfStars > 0 else { return }
                                    FDHaptics.tap()
                                    withAnimation(.fdSnap) { draft.potentialHalfStars -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(halfStars > 0 ? FDTheme.destructive : Color.white.opacity(0.15))
                                }
                                .buttonStyle(.plain)

                                ForEach(0..<FDPotentialShop.maxStars, id: \.self) { i in
                                    let filled = halfStars >= (i + 1) * 2
                                    let half = halfStars == i * 2 + 1
                                    Image(systemName: filled ? "star.fill" : (half ? "star.lefthalf.fill" : "star"))
                                        .font(.title2)
                                        .foregroundStyle(filled || half
                                                         ? (halfStars < FDPotentialShop.freeHalfStars
                                                            ? FDTheme.destructive
                                                            : (halfStars > FDPotentialShop.freeHalfStars
                                                               ? FDTheme.amber : FDTheme.success))
                                                         : Color.white.opacity(0.15))
                                }

                                Button {
                                    guard halfStars < FDPotentialShop.freeHalfStars + maxAffordable else { return }
                                    FDHaptics.tap()
                                    withAnimation(.fdSnap) { draft.potentialHalfStars += 1 }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(halfStars < FDPotentialShop.freeHalfStars + maxAffordable
                                                         ? FDTheme.success : Color.white.opacity(0.15))
                                }
                                .buttonStyle(.plain)

                                Spacer()
                                Text("\(FDPotentialShop.label(halfStars: halfStars))/\(FDPotentialShop.maxStars)")
                                    .font(FDFont.mono(17, bold: true))
                                    .foregroundStyle(handicap > 0 ? FDTheme.destructive
                                                     : (bought > 0 ? FDTheme.amber : FDTheme.success))
                            }

                            if handicap > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Carrière handicapée : plafond plus bas, bons paliers de talent plus rares, et tu démarres plus bas dans la pyramide.")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(FDTheme.destructive)
                                    Text("En échange, cette carrière rapportera \(handicap * 15) % de points en plus à la retraite.")
                                        .font(.subheadline)
                                        .foregroundStyle(FDTheme.success)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else if bought > 0 {
                                HStack {
                                    Text("Coût : \(cost) points")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(FDTheme.amber)
                                    Spacer()
                                    Text("Reste \(engine.lifetimePoints - cost)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            } else if maxAffordable == 0 {
                                Text("Il te faut \(FDPotentialShop.costOfHalfStar(1)) points pour la demi-étoile suivante. Termine une carrière pour en gagner : les points ne servent qu'à la carrière que tu lances ensuite. Descendre, en revanche, est gratuit.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Tes points peuvent remplir \(FDPotentialShop.label(halfStars: maxAffordable)) étoile(s) de plus, pour cette carrière-là seulement. Les étoiles ne ferment aucune porte : elles rendent seulement une grande carrière plus ou moins probable, et orientent les clubs qu'on te proposera. À étoiles égales, deux carrières ne décollent jamais au même rythme.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(13)
                    }
                    .fdCardSurface()
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(FDTheme.amber.opacity(0.22), lineWidth: 1))

                    // The player card: everything decided in the previous steps, in one place.
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Text(fdFlag(for: draft.nationality))
                                .font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(draft.firstName) \(draft.lastName)")
                                    .font(FDFont.display(23))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("Né à \(draft.birthCity), \(draft.nationality)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            Spacer(minLength: 0)
                            VStack(spacing: 1) {
                                Text(draft.position.rawValue.prefix(3).uppercased())
                                    .font(FDFont.body(16, black: true))
                                    .foregroundStyle(FDTheme.primary)
                                Text("Pied \(draft.foot.rawValue.lowercased())")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 9).padding(.vertical, 6)
                            .background(FDTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(13)

                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                        ficheRow(icon: "figure.soccer", label: "Poste", value: draft.position.rawValue,
                                 detail: nil, color: FDTheme.primary)
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        ficheRow(icon: draft.background.flavorIcon, label: "Origine", value: draft.background.rawValue,
                                 detail: draft.background.flavorText, color: FDTheme.accentTeal)
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        ficheRow(icon: draft.personality.flavorIcon, label: "Personnalité", value: draft.personality.rawValue,
                                 detail: draft.personality.flavorText, color: FDTheme.warning)
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        ficheRow(icon: draft.style.flavorIcon, label: "Style", value: draft.style.rawValue,
                                 detail: draft.style.flavorText, color: FDTheme.destructive)
                    }
                    .fdCardSurface()

                    // Competences carried into this career, when the player owns any.
                    if !available.isEmpty {
                        VStack(spacing: 0) {
                            creationSectionHeader(icon: "bolt.badge.a.fill", title: "Compétences (\(draft.equippedCompetenceIDs.count)/\(FDMaxEquippedCompetences))")

                            ForEach(available) { competence in
                                let isOn = draft.equippedCompetenceIDs.contains(competence.id)
                                let isFull = draft.equippedCompetenceIDs.count >= FDMaxEquippedCompetences

                                FDCompetenceChoiceRow(
                                    competence: competence,
                                    selected: isOn,
                                    charges: engine.remainingCharges(competence.id),
                                    disabled: !isOn && isFull
                                ) {
                                    FDHaptics.tap()
                                    withAnimation(.fdSnap) {
                                        if isOn {
                                            draft.equippedCompetenceIDs.removeAll { $0 == competence.id }
                                        } else if !isFull {
                                            draft.equippedCompetenceIDs.append(competence.id)
                                        }
                                    }
                                }

                                if competence.id != available.last?.id {
                                    Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                                }
                            }

                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                            Text("Une compétence à usage unique est consommée au lancement de la carrière. Celles achetées définitivement restent disponibles.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 11).padding(.vertical, 8)
                        }
                        .fdCardSurface()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            stickyFooter(title: "Continuer →", enabled: true) { advance() }
        }
    }

    /// One line of the player card: an icon, what it is, what was chosen, and the one-line
    /// flavour text that came with it.
    private func ficheRow(icon: String, label: String, value: String, detail: String?, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 20)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(label.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(FDFont.body(17, black: true))
                        .foregroundStyle(FDTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
    }

    // MARK: - Step 6: Club

    private var clubStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    FDCreationStepHeader(
                        step: stepNumber(.club), of: steps.count,
                        icon: "building.columns.fill",
                        title: "Premier club",
                        subtitle: "Où commence ton aventure ?"
                    )

                    // Draft summary
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.subheadline.weight(.bold)).foregroundStyle(FDTheme.primary)
                            Text("TON PROFIL")
                                .font(FDFont.body(16, black: true)).foregroundStyle(FDTheme.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(FDTheme.primary.opacity(0.08))

                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                        // These are words, not figures — they use the app's label face rather
                        // than the monospaced one reserved for stats and money.
                        HStack(spacing: 0) {
                            VStack(spacing: 2) {
                                Text(draft.position.rawValue)
                                    .font(FDFont.body(17, black: true)).foregroundStyle(FDTheme.primary)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                Text("POSTE").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 32)
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(fdFlag(for: draft.nationality)).font(.system(size: 17))
                                    Text(draft.nationality)
                                        .font(FDFont.body(17, black: true)).foregroundStyle(.white)
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                }
                                Text("NATION").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 32)
                            VStack(spacing: 2) {
                                Text(draft.personality.rawValue)
                                    .font(FDFont.body(17, black: true)).foregroundStyle(FDTheme.accentTeal)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                Text("PERSO").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 10)
                    }
                    .fdCardSurface()

                    // Club picker
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "building.columns.fill", title: "Choisis ton premier club")

                        // Les étoiles offertes comptent ici comme les autres : à deux étoiles
                        // on démarre en deuxième division en moyenne, avec un club au-dessus
                        // et deux en dessous. Chaque ligne dit ce que ce choix coûtera.
                        let totalStars = FDPotentialShop.stars(halfStars: draft.potentialHalfStars)
                        let centre = engine.startCentralDivision(nationality: draft.nationality, totalStars: totalStars)
                        ForEach(engine.availableStartClubs(nationality: draft.nationality, potentialStars: totalStars), id: \.id) { club in
                            FDClubChoiceRow(club: club,
                                            note: fdStartClubNote(division: club.division, centre: centre),
                                            selected: draft.club?.id == club.id) {
                                selectAndAdvance { draft.club = club }
                            }
                            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        }
                    }
                    .fdCardSurface()
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            stickyFooter(
                title: "Lancer ma carrière",
                icon: "arrow.right.circle.fill",
                enabled: draft.club != nil
            ) {
                FDHaptics.success()
                engine.startCareer(from: draft)
                screen = .game
            }
        }
    }

    // MARK: - Helper views

    private func creationSectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(FDTheme.primary)
            Text(title.uppercased())
                .font(FDFont.body(14, black: true))
                .foregroundStyle(FDTheme.primary)
            Spacer()
        }
        .padding(.horizontal, 11).padding(.vertical, 6)
        .background(FDTheme.primary.opacity(0.07))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
        }
    }

}

private func fdPositionIcon(_ position: FDPosition) -> String {
    switch position {
    case .gardien: return "hand.raised.fill"
    case .defenseur: return "shield.fill"
    case .milieu: return "arrow.triangle.swap"
    case .attaquant: return "soccerball"
    }
}

private struct FDFlagChoice: View {
    let flag: String
    let name: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // A flag card: the flag owns the top of the tile at its natural proportions —
            // never stretched — with the country name on its own line underneath.
            VStack(spacing: 0) {
                Text(flag)
                    .font(.system(size: 42))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.22))

                Text(name)
                    .font(FDFont.body(16, black: selected))
                    .foregroundStyle(selected ? .white : FDTheme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 5)
                    .background(selected ? FDTheme.primary.opacity(0.22) : Color.white.opacity(0.05))
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? FDTheme.primary : Color.white.opacity(0.10),
                            lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? FDTheme.primary.opacity(0.4) : .clear, radius: 5)
        }
        .buttonStyle(FDChoiceButtonStyle())
        .animation(.fdSnap, value: selected)
    }
}

private struct FDPositionRow: View {
    let position: FDPosition
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? FDTheme.primary.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)
                    Image(systemName: fdPositionIcon(position))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected ? FDTheme.primary : .secondary)
                }
                Text(position.rawValue)
                    .font(FDFont.body(18, black: selected))
                    .foregroundStyle(selected ? FDTheme.textPrimary : FDTheme.textMuted)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FDTheme.primary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 11).padding(.vertical, 9)
        }
        .buttonStyle(FDChoiceButtonStyle())
        .animation(.fdSnap, value: selected)
    }
}

private func fdTierColor(_ tier: FDClubTier) -> Color {
    switch tier {
    case .elite: return FDTheme.amber
    case .pro: return FDTheme.primary
    case .semi: return FDTheme.accentTeal
    case .amateur: return .secondary
    }
}

/// Ce que vaut ce club-là par rapport au niveau moyen du joueur : au-dessus, c'est plus dur
/// et il faudra se battre pour jouer ; en dessous, on joue tout de suite mais on progresse
/// dans un cadre plus modeste.
func fdStartClubNote(division: Int, centre: Int) -> (text: String, color: Color) {
    if division < centre { return ("Au-dessus de ton niveau · plus dur", FDTheme.destructive) }
    if division > centre { return ("Sous ton niveau · tu joueras tout de suite", FDTheme.success) }
    return ("À ton niveau", FDTheme.amber)
}

private struct FDClubChoiceRow: View {
    let club: FDClub
    var note: (text: String, color: Color)? = nil
    let selected: Bool
    let action: () -> Void

    private var tint: Color { fdTierColor(club.tier) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? FDTheme.primary.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)
                    Text(fdFlag(for: club.country))
                        .font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(club.name)
                        .font(FDFont.body(18, black: selected))
                        .foregroundStyle(selected ? FDTheme.textPrimary : FDTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(club.city) · \(club.leagueName)")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note = note {
                        Text(note.text)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(note.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Text(club.tier.rawValue)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(tint.opacity(0.2)))
                    .foregroundStyle(tint)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FDTheme.primary)
                }
            }
            .padding(.horizontal, 11).padding(.vertical, 9)
        }
        .buttonStyle(FDChoiceButtonStyle())
        .animation(.fdSnap, value: selected)
    }
}

/// Compact square-ish tile used by the profile step's personality/style grids — icon over
/// label, no description, so seven options take four rows instead of seven.
private struct FDProfileTile: View {
    let icon: String
    let title: String
    let selected: Bool
    var accent: Color = FDTheme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(selected ? accent : .secondary)
                Text(title)
                    .font(FDFont.body(16, black: selected))
                    .foregroundStyle(selected ? FDTheme.textPrimary : FDTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? accent.opacity(0.16) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? accent : Color.white.opacity(0.08), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(FDChoiceButtonStyle())
        .animation(.fdSnap, value: selected)
    }
}

private struct FDProfileChoiceRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let selected: Bool
    var accent: Color = FDTheme.primary
    var showChevronWhenUnselected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(selected ? accent.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected ? accent : .secondary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(FDFont.body(18, black: selected))
                        .foregroundStyle(selected ? FDTheme.textPrimary : FDTheme.textMuted)
                    Text(subtitle)
                        .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(accent)
                } else if showChevronWhenUnselected {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 11).padding(.vertical, 8)
            .background(selected ? accent.opacity(0.06) : Color.clear)
        }
        .buttonStyle(FDChoiceButtonStyle())
        .animation(.fdSnap, value: selected)
    }
}

// MARK: - Creation UI helpers

private struct FDCreationStepHeader: View {
    let step: Int
    let of: Int
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(FDTheme.primary.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(FDTheme.primary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Étape \(step)/\(of)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FDTheme.primary.opacity(0.7))
                Text(title)
                    .font(FDFont.display(21))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

/// One equippable competence in the creation flow: a checkbox-style row showing whether
/// it's owned outright or backed by single-career charges.
private struct FDCompetenceChoiceRow: View {
    let competence: FDCompetence
    let selected: Bool
    /// nil when the competence is owned outright, otherwise the charges left.
    let charges: Int?
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? FDTheme.primary.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 32, height: 32)
                    Image(systemName: competence.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(selected ? FDTheme.primary : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(competence.name)
                            .font(FDFont.body(17, black: selected))
                            .foregroundStyle(selected ? FDTheme.textPrimary : FDTheme.textMuted)
                        if let charges {
                            Text("×\(charges)")
                                .font(FDFont.mono(14, bold: true))
                                .foregroundStyle(FDTheme.success)
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(FDTheme.success.opacity(0.16), in: Capsule())
                        } else {
                            Text("ACQUISE")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(FDTheme.amber)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(FDTheme.amber.opacity(0.16), in: Capsule())
                        }
                    }
                    Text(competence.description)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(selected ? FDTheme.primary : Color.white.opacity(0.25))
            }
            .padding(.horizontal, 11).padding(.vertical, 8)
            .background(selected ? FDTheme.primary.opacity(0.06) : Color.clear)
        }
        .buttonStyle(FDChoiceButtonStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .animation(.fdSnap, value: selected)
    }
}

// MARK: - Style/Personality extensions

private extension FDStyle {
    var flavorIcon: String {
        switch self {
        case .technicien: return "wand.and.stars"
        case .rapide: return "bolt.fill"
        case .puissant: return "bolt.circle.fill"
        case .createur: return "paintbrush.fill"
        case .finisseur: return "scope"
        case .recuperateur: return "shield.fill"
        case .leader: return "crown.fill"
        }
    }
    var flavorText: String {
        switch self {
        case .technicien: return "Le ballon t'obéit. Contrôle, vision, précision — c'est ton truc."
        case .rapide: return "Tu cherches constamment la profondeur. Le sprint, le duel, l'explosion."
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
        case .ambitieux: return "flame.fill"
        case .discipline: return "checklist"
        case .charismatique: return "sparkles"
        case .reserve: return "figure.stand"
        case .provocateur: return "theatermasks.fill"
        case .travailleur: return "hammer.fill"
        case .irregulier: return "waveform.path.ecg"
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
        case .modeste: return "house.fill"
        case .stable: return "scalemass.fill"
        case .aisee: return "briefcase.fill"
        case .footballeur: return "person.2.fill"
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
