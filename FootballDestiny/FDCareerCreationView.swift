import SwiftUI
import Foundation

private enum FDCreationStep: Int, CaseIterable {
    case identityNationality, position, background, profile, settings, club
}

struct FDCareerCreationView: View {
    @ObservedObject var engine: FDGameEngine
    @Binding var screen: FDScreen

    @State private var stepIndex = 0
    @State private var draft = FDCreationDraft()

    private let steps = FDCreationStep.allCases
    private var currentStep: FDCreationStep { steps[stepIndex] }

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            advance()
        }
    }

    @ViewBuilder
    private func stickyFooter(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
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
            draft.nationality = FDNations.randomElement() ?? draft.nationality
            regenerateName()
        case .position: draft.position = FDPosition.allCases.randomElement() ?? draft.position
        case .background: draft.background = FDBackground.allCases.randomElement() ?? draft.background
        case .profile:
            draft.personality = FDPersonality.allCases.randomElement() ?? draft.personality
            draft.style = FDStyle.allCases.randomElement() ?? draft.style
        case .settings, .club: break
        }
    }

    private func regenerateName() {
        let nameData = FDNameBank.random(for: draft.nationality)
        draft.firstName = nameData.first
        draft.lastName = nameData.last
    }

    // MARK: - Step 1: Identity & Nationality

    private var identityNationalityStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Step header
                    FDCreationStepHeader(
                        step: 1, of: steps.count,
                        icon: "person.fill",
                        title: "Identité",
                        subtitle: "Qui es-tu ?"
                    )

                    // Name card
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "textformat", title: "Nom & prénom")

                        VStack(spacing: 12) {
                            FDCreationField(label: "Prénom", text: $draft.firstName, placeholder: "Prénom")
                            FDCreationField(label: "Nom", text: $draft.lastName, placeholder: "Nom de famille")
                            FDCreationField(label: "Ville de naissance", text: $draft.birthCity, placeholder: "Ville")
                        }
                        .padding(14)
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    // Nationality
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "globe.europe.africa.fill", title: "Nationalité")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(FDNations, id: \.self) { nation in
                                    Button {
                                        FDHaptics.tap()
                                        draft.nationality = nation
                                        regenerateName()
                                    } label: {
                                        Text(nation)
                                            .font(FDFont.body(13))
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(
                                                Capsule().fill(draft.nationality == nation
                                                               ? FDTheme.primary
                                                               : Color.white.opacity(0.07))
                                            )
                                            .foregroundStyle(draft.nationality == nation ? .white : FDTheme.textPrimary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    // Pied fort
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "boot.fill", title: "Pied fort")

                        HStack(spacing: 0) {
                            ForEach(FDFoot.allCases, id: \.self) { foot in
                                Button {
                                    FDHaptics.tap()
                                    draft.foot = foot
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: foot == .droit ? "hand.point.right.fill" : "hand.point.left.fill")
                                            .font(.title3)
                                            .foregroundStyle(draft.foot == foot ? FDTheme.primary : .secondary)
                                        Text(foot.rawValue)
                                            .font(FDFont.body(13, black: draft.foot == foot))
                                            .foregroundStyle(draft.foot == foot ? FDTheme.textPrimary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(draft.foot == foot ? FDTheme.primary.opacity(0.12) : Color.clear)
                                }
                                .buttonStyle(.plain)
                                if foot != FDFoot.allCases.last {
                                    Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 40)
                                }
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
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
                VStack(spacing: 16) {
                    FDCreationStepHeader(
                        step: 2, of: steps.count,
                        icon: "figure.soccer",
                        title: "Poste",
                        subtitle: "Où évolues-tu ?"
                    )

                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "figure.soccer", title: "Position sur le terrain")

                        ForEach(FDPosition.allCases) { position in
                            Button {
                                selectAndAdvance { draft.position = position }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(draft.position == position ? FDTheme.primary.opacity(0.2) : Color.white.opacity(0.06))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: fdPositionIcon(position))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(draft.position == position ? FDTheme.primary : .secondary)
                                    }
                                    Text(position.rawValue)
                                        .font(FDFont.body(14, black: draft.position == position))
                                        .foregroundStyle(draft.position == position ? FDTheme.textPrimary : FDTheme.textMuted)
                                    Spacer()
                                    if draft.position == position {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(FDTheme.primary)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            if position != FDPosition.allCases.last {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
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
                VStack(spacing: 16) {
                    FDCreationStepHeader(
                        step: 3, of: steps.count,
                        icon: "house.fill",
                        title: "Origine",
                        subtitle: "D'où viens-tu ?"
                    )

                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "house.fill", title: "Milieu familial")

                        ForEach(FDBackground.allCases, id: \.self) { bg in
                            Button {
                                selectAndAdvance { draft.background = bg }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(bg.flavorIcon)
                                        .font(.title2)
                                        .frame(width: 40)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(bg.rawValue)
                                            .font(FDFont.body(14, black: draft.background == bg))
                                            .foregroundStyle(draft.background == bg ? FDTheme.textPrimary : FDTheme.textMuted)
                                        Text(bg.flavorText)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    if draft.background == bg {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(FDTheme.primary)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 13)
                                .background(draft.background == bg ? FDTheme.primary.opacity(0.06) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            if bg != FDBackground.allCases.last {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
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
                VStack(spacing: 16) {
                    FDCreationStepHeader(
                        step: 4, of: steps.count,
                        icon: "person.crop.circle.fill.badge.checkmark",
                        title: "Profil",
                        subtitle: "Quel joueur es-tu ?"
                    )

                    // Personnalité
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "brain.fill", title: "Personnalité")

                        ForEach(FDPersonality.allCases, id: \.self) { personality in
                            Button {
                                FDHaptics.tap()
                                draft.personality = personality
                            } label: {
                                HStack(spacing: 12) {
                                    Text(personality.flavorIcon)
                                        .font(.title2)
                                        .frame(width: 40)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(personality.rawValue)
                                            .font(FDFont.body(14, black: draft.personality == personality))
                                            .foregroundStyle(draft.personality == personality ? FDTheme.textPrimary : FDTheme.textMuted)
                                        Text(personality.flavorText)
                                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                    Spacer()
                                    if draft.personality == personality {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(FDTheme.primary)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 11)
                                .background(draft.personality == personality ? FDTheme.primary.opacity(0.06) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            if personality != FDPersonality.allCases.last {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    // Style de jeu
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "figure.run", title: "Style de jeu")

                        ForEach(FDStyle.allCases, id: \.self) { style in
                            Button {
                                FDHaptics.tap()
                                draft.style = style
                            } label: {
                                HStack(spacing: 12) {
                                    Text(style.flavorIcon)
                                        .font(.title2)
                                        .frame(width: 40)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(style.rawValue)
                                            .font(FDFont.body(14, black: draft.style == style))
                                            .foregroundStyle(draft.style == style ? FDTheme.textPrimary : FDTheme.textMuted)
                                        Text(style.flavorText)
                                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                    Spacer()
                                    if draft.style == style {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(FDTheme.accentTeal)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 11)
                                .background(draft.style == style ? FDTheme.accentTeal.opacity(0.06) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            if style != FDStyle.allCases.last {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    FDCreationStepHeader(
                        step: 5, of: steps.count,
                        icon: "gearshape.fill",
                        title: "Paramètres",
                        subtitle: "Comment veux-tu jouer ?"
                    )

                    // Difficulté
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "slider.horizontal.3", title: "Difficulté")

                        ForEach(FDDifficulty.allCases, id: \.self) { diff in
                            Button {
                                FDHaptics.tap()
                                draft.difficulty = diff
                            } label: {
                                HStack(spacing: 14) {
                                    let color: Color = diff == .facile ? FDTheme.success : diff == .normal ? FDTheme.primary : FDTheme.destructive
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(draft.difficulty == diff ? color.opacity(0.2) : Color.white.opacity(0.06))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: diff == .facile ? "tortoise.fill" : diff == .normal ? "figure.run" : "bolt.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(draft.difficulty == diff ? color : .secondary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(diff.rawValue)
                                            .font(FDFont.body(14, black: draft.difficulty == diff))
                                            .foregroundStyle(draft.difficulty == diff ? FDTheme.textPrimary : FDTheme.textMuted)
                                        Text(diff.hint)
                                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                    Spacer()
                                    if draft.difficulty == diff {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(color)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 11)
                            }
                            .buttonStyle(.plain)
                            if diff != FDDifficulty.allCases.last {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    // Mode
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "play.circle.fill", title: "Mode de jeu")

                        ForEach(FDMode.allCases) { mode in
                            Button {
                                FDHaptics.tap()
                                draft.mode = mode
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(draft.mode == mode ? FDTheme.primary.opacity(0.2) : Color.white.opacity(0.06))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: mode == .narratif ? "book.fill" : "bolt.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(draft.mode == mode ? FDTheme.primary : .secondary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mode.rawValue)
                                            .font(FDFont.body(14, black: draft.mode == mode))
                                            .foregroundStyle(draft.mode == mode ? FDTheme.textPrimary : FDTheme.textMuted)
                                        Text(mode.hint)
                                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                    Spacer()
                                    if draft.mode == mode {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(FDTheme.primary)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 11)
                            }
                            .buttonStyle(.plain)
                            if mode != FDMode.allCases.last {
                                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                            }
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    // Potentiel (méta-progression)
                    let maxAffordable = FDPotentialShop.maxAffordableStars(points: engine.lifetimePoints)
                    if maxAffordable > 0 {
                        VStack(spacing: 0) {
                            creationSectionHeader(icon: "crown.fill", title: "Potentiel de départ")

                            VStack(spacing: 12) {
                                HStack {
                                    Text("🏆 \(engine.lifetimePoints) points de carrière cumulés")
                                        .font(FDFont.body(13))
                                        .foregroundStyle(FDTheme.amber)
                                    Spacer()
                                }

                                HStack(spacing: 4) {
                                    ForEach(0..<FDPotentialShop.maxStars, id: \.self) { i in
                                        Image(systemName: i < draft.potentialStars ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundStyle(i < draft.potentialStars ? FDTheme.amber : Color.white.opacity(0.2))
                                            .onTapGesture {
                                                let target = i + 1
                                                if target <= maxAffordable {
                                                    draft.potentialStars = draft.potentialStars == target ? 0 : target
                                                }
                                            }
                                    }
                                }

                                if draft.potentialStars > 0 {
                                    HStack {
                                        Text("Coût : 🏆 \(FDPotentialShop.cumulativeCost(for: draft.potentialStars)) points")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(FDTheme.amber)
                                        Spacer()
                                        Text("Potentiel +\(draft.potentialStars * 5)%")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(FDTheme.success)
                                    }
                                }

                                Text("Chaque étoile augmente ton plafond de potentiel — une carrière parfaite peut en valoir davantage.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                        }
                        .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                        .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(FDTheme.amber.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            stickyFooter(title: "Continuer →", enabled: true) { advance() }
        }
    }

    // MARK: - Step 6: Club

    private var clubStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    FDCreationStepHeader(
                        step: 6, of: steps.count,
                        icon: "building.columns.fill",
                        title: "Premier club",
                        subtitle: "Où commence ton aventure ?"
                    )

                    // Draft summary
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.caption.weight(.bold)).foregroundStyle(FDTheme.primary)
                            Text("TON PROFIL")
                                .font(FDFont.body(11, black: true)).foregroundStyle(FDTheme.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(FDTheme.primary.opacity(0.08))

                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                        HStack(spacing: 0) {
                            VStack(spacing: 2) {
                                Text(draft.position.rawValue.components(separatedBy: " ").first ?? draft.position.rawValue)
                                    .font(FDFont.mono(13, bold: true)).foregroundStyle(FDTheme.primary)
                                Text("POSTE").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 32)
                            VStack(spacing: 2) {
                                Text(draft.nationality)
                                    .font(FDFont.mono(13, bold: true)).foregroundStyle(.white)
                                Text("NATION").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 32)
                            VStack(spacing: 2) {
                                Text(draft.personality.rawValue)
                                    .font(FDFont.mono(13, bold: true)).foregroundStyle(FDTheme.accentTeal).lineLimit(1).minimumScaleFactor(0.7)
                                Text("PERSO").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 10)
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))

                    // Club picker
                    VStack(spacing: 0) {
                        creationSectionHeader(icon: "building.columns.fill", title: "Choisis ton premier club")

                        ForEach(engine.availableStartClubs(nationality: draft.nationality, potentialStars: draft.potentialStars), id: \.id) { club in
                            Button {
                                selectAndAdvance { draft.club = club }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(draft.club?.id == club.id ? FDTheme.primary.opacity(0.2) : Color.white.opacity(0.06))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "soccerball")
                                            .font(.system(size: 14))
                                            .foregroundStyle(draft.club?.id == club.id ? FDTheme.primary : .secondary)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(club.name)
                                            .font(FDFont.body(14, black: draft.club?.id == club.id))
                                            .foregroundStyle(draft.club?.id == club.id ? FDTheme.textPrimary : FDTheme.textMuted)
                                        Text("\(club.country) · \(club.tier.rawValue)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    // Tier badge
                                    Text(club.tier.rawValue)
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Capsule().fill(tierColor(club.tier).opacity(0.2)))
                                        .foregroundStyle(tierColor(club.tier))
                                    if draft.club?.id == club.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(FDTheme.primary)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                        }
                    }
                    .background(FDTheme.card, in: RoundedRectangle(cornerRadius: FDTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: FDTheme.radiusCard).stroke(Color.white.opacity(0.07), lineWidth: 1))
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            stickyFooter(
                title: "Lancer ma carrière 🚀",
                enabled: draft.club != nil
            ) {
                FDHaptics.success()
                engine.startCareer(from: draft)
            }
        }
    }

    // MARK: - Helper views

    private func creationSectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(FDTheme.primary)
            Text(title.uppercased())
                .font(FDFont.body(10, black: true))
                .foregroundStyle(FDTheme.primary)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(FDTheme.primary.opacity(0.07))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
        }
    }

    private func tierColor(_ tier: FDClubTier) -> Color {
        switch tier {
        case .elite: return FDTheme.amber
        case .pro: return FDTheme.primary
        case .semi: return FDTheme.accentTeal
        case .amateur: return .secondary
        }
    }

    private func fdPositionIcon(_ position: FDPosition) -> String {
        switch position {
        case .gardien: return "hand.raised.fill"
        case .defenseurCentral, .lateral: return "shield.fill"
        case .milieuDefensif, .milieuRelayeur, .milieuOffensif: return "arrow.triangle.swap"
        case .ailier, .avantCentre: return "soccerball"
        }
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
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FDTheme.primary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Étape \(step)/\(of)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FDTheme.primary.opacity(0.7))
                Text(title)
                    .font(FDFont.display(20))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

private struct FDCreationField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(FDTheme.primary.opacity(0.7))
            TextField(placeholder, text: $text)
                .font(FDFont.body(15))
                .foregroundStyle(FDTheme.textPrimary)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(FDTheme.bg.opacity(0.6), in: RoundedRectangle(cornerRadius: FDTheme.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: FDTheme.radiusMD)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

// MARK: - Style/Personality extensions

private extension FDStyle {
    var flavorIcon: String {
        switch self {
        case .technicien: return "🎩"
        case .attaquant: return "⚡"
        case .finisseur: return "🎯"
        case .recuperateur: return "🛡️"
        case .leader: return "👑"
        }
    }
    var flavorText: String {
        switch self {
        case .technicien: return "Le ballon t'obéit. Contrôle, vision, précision — c'est ton truc."
        case .attaquant: return "Tu cherches constamment la profondeur. Le sprint, le duel, l'explosion."
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
