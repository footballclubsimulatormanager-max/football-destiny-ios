import Foundation
import Combine

final class FDGameEngine: ObservableObject {
    @Published var player: FDPlayer?
    @Published var currentScene: FDCurrentScene = .none
    @Published var toast: String? = nil

    /// Persists across careers (survives resetSave): every retirement banks points here,
    /// and new careers get a small starting-potential boost based on the running total.
    @Published var lifetimePoints: Int = UserDefaults.standard.integer(forKey: "footballDestinyLifetimePoints_v1")

    /// The Boutique/Défis currency: 0-10 "pièces" earned per retirement based on how good
    /// that career was, deliberately scarcer than lifetimePoints.
    @Published var legendCoins: Int = UserDefaults.standard.integer(forKey: "footballDestinyLegendCoins_v1")
    /// Competences bought outright (5x the base price): available to equip in every career.
    @Published var ownedCompetenceIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "footballDestinyOwnedCompetences_v1") ?? [])
    /// Single-career charges bought at the base price, consumed when the career starts.
    @Published var competenceCharges: [String: Int] = (UserDefaults.standard.dictionary(forKey: "footballDestinyCompetenceCharges_v1") as? [String: Int]) ?? [:]
    @Published var unlockedLegendIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "footballDestinyUnlockedLegends_v1") ?? [])
    @Published var conqueredLegendIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "footballDestinyConqueredLegends_v1") ?? [])
    @Published var archivedCareers: [FDPlayer] = []

    private var activeLegendChallengeID: String?
    private var usedSceneIds: Set<String> = []
    private var sceneCooldown: [String: Int] = [:]
    private var suppressToast = false
    private var toastDismissWorkItem: DispatchWorkItem?
    private var pendingTournament: FDTournamentSummary?
    /// L'offre reçue à l'intersaison, présentée comme un choix avant la reprise plutôt que
    /// résolue en silence dans le bilan.
    private var pendingOffer: (club: FDClub, fee: Int)?

    /// Rangées dans `sceneCooldown`, ces clés ne peuvent croiser aucun identifiant de scène
    /// et évitent d'ajouter un champ à la sauvegarde, qui casserait les parties en cours.

    private static let storageKey = "footballDestinySave_v1_native"
    private static let lifetimePointsKey = "footballDestinyLifetimePoints_v1"
    private static let legendCoinsKey = "footballDestinyLegendCoins_v1"
    private static let ownedCompetencesKey = "footballDestinyOwnedCompetences_v1"
    private static let chargesKey = "footballDestinyCompetenceCharges_v1"
    private static let unlockedLegendsKey = "footballDestinyUnlockedLegends_v1"
    private static let conqueredLegendsKey = "footballDestinyConqueredLegends_v1"
    private static let archiveKey = "footballDestinyArchive_v1"
    private static let recentScenesKey = "footballDestinyRecentScenes_v1"

    /// Les scènes vues lors des dernières carrières, pas seulement celle en cours. Quelqu'un
    /// qui enchaîne cent carrières sur plusieurs mois retomberait sinon sur les mêmes textes
    /// dès la deuxième : à l'intérieur d'une carrière on ne se répète jamais, mais d'une
    /// carrière à l'autre le tirage repartait de zéro. Fenêtre glissante : les plus vieilles
    /// sortent, et une scène redevient disponible quand tout le reste a défilé.
    private var recentSceneIds: [String] = []
    private static let recentScenesWindow = 260

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.archiveKey),
           let decoded = try? JSONDecoder().decode([FDPlayer].self, from: data) {
            archivedCareers = decoded
        }
        recentSceneIds = UserDefaults.standard.stringArray(forKey: Self.recentScenesKey) ?? []
    }

    /// Retient une scène servie, toutes carrières confondues.
    private func rememberScene(_ id: String) {
        guard !id.hasPrefix("generic_") else { return }
        recentSceneIds.removeAll { $0 == id }
        recentSceneIds.append(id)
        if recentSceneIds.count > Self.recentScenesWindow {
            recentSceneIds.removeFirst(recentSceneIds.count - Self.recentScenesWindow)
        }
        UserDefaults.standard.set(recentSceneIds, forKey: Self.recentScenesKey)
    }

    // MARK: - Save / load

    func hasSave() -> Bool {
        UserDefaults.standard.data(forKey: Self.storageKey) != nil
    }

    func saveGame() {
        guard let player = player else { return }
        let blob = FDSaveBlob(player: player, usedSceneIds: Array(usedSceneIds), sceneCooldown: sceneCooldown)
        if let data = try? JSONEncoder().encode(blob) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    func loadGame() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let blob = try? JSONDecoder().decode(FDSaveBlob.self, from: data) else { return false }
        player = blob.player
        usedSceneIds = Set(blob.usedSceneIds)
        sceneCooldown = blob.sceneCooldown
        if let p = player, !p.retired {
            currentScene = generateNextEvent()
            autoResolveExpress()
        } else {
            currentScene = .none
        }
        return true
    }

    func resetSave() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        player = nil
        currentScene = .none
        usedSceneIds = []
        sceneCooldown = [:]
        activeLegendChallengeID = nil
    }

    // MARK: - Career creation

    func startCareer(draft: FDCreationDraft, club: FDClub, legendChallengeID: String? = nil) {
        activeLegendChallengeID = legendChallengeID
        // Le potentiel de départ se déplace dans les deux sens autour des deux étoiles
        // acquises : vers le haut en dépensant des points, vers le bas gratuitement pour
        // ceux qui veulent une carrière qui ne pardonne rien.
        let halfStars = min(max(draft.potentialHalfStars, 0), FDPotentialShop.maxHalfStars)
        let halfBought = max(0, halfStars - FDPotentialShop.freeHalfStars)
        let halfHandicap = max(0, FDPotentialShop.freeHalfStars - halfStars)
        let starCost = FDPotentialShop.cumulativeCost(halfStars: halfBought)
        if starCost > 0 {
            lifetimePoints = max(0, lifetimePoints - starCost)
            UserDefaults.standard.set(lifetimePoints, forKey: Self.lifetimePointsKey)
        }
        let metaBonus = min(10, lifetimePoints / 25)

        // Only the competences the player chose to bring into this career apply — at most
        // FDMaxEquippedCompetences of them — and each single-career charge is spent here.
        let equipped = Array(draft.equippedCompetenceIDs.prefix(FDMaxEquippedCompetences))
        for id in equipped where !ownedCompetenceIDs.contains(id) {
            if let left = competenceCharges[id], left > 0 {
                competenceCharges[id] = left - 1 > 0 ? left - 1 : nil
            }
        }
        persistCompetences()

        var competencePotential = 0, competenceMoney = 0, competenceReputation = 0
        var competenceForme = 0, competenceConfiance = 0, competenceMoral = 0
        for id in equipped {
            guard let c = FDCompetences.first(where: { $0.id == id }) else { continue }
            switch c.effect {
            case .potential(let v): competencePotential += v
            case .money(let v): competenceMoney += v
            case .reputation(let v): competenceReputation += v
            case .forme(let v): competenceForme += v
            case .confiance(let v): competenceConfiance += v
            case .moral(let v): competenceMoral += v
            }
        }

        // Deux étoiles offertes à tout le monde : sans elles, les premières carrières —
        // celles qu'on joue justement sans points en banque — plafonnaient trop bas pour
        // aller nulle part. Les étoiles achetées s'ajoutent par-dessus, elles gardent donc
        // toute leur valeur.
        // Le talent est tiré ici, une fois pour toutes, et n'est jamais annoncé : deux
        // carrières lancées avec les mêmes étoiles ne valent pas la même chose. L'écart aux
        // deux étoiles de départ le tire vers le haut… ou vers le bas.
        let talent = fdDrawTalentTier(
            starsBought: FDPotentialShop.stars(halfStars: halfStars) - Double(FDPotentialShop.freeStars))
        let potBias = 14 + halfStars * 2 + metaBonus + competencePotential + talent.potentialBias
        let talentSeed = Int.random(in: -6...10)
        let weights = draft.position.weights
        let jitterRange: ClosedRange<Int> = draft.personality == .irregulier ? -14...17 : -8...9

        var attrs: [String: Int] = [:]
        for a in FDAttribute.allCases {
            let catW = weights.value(for: a.category)
            var v = 22 + Int((catW * 26).rounded()) + Int((Double(talentSeed) * 0.6).rounded()) + Int.random(in: jitterRange)
            v += styleBonus(draft.style, category: a.category)
            v += personalityBonus(draft.personality, category: a.category)
            v += backgroundBonus(draft.background, category: a.category)
            v += footBonus(draft.foot, category: a.category)
            if Double.random(in: 0...1) < 0.14 { v += Int.random(in: 6...13) }
            attrs[a.rawValue] = min(max(v, 10), 62)
        }
        // Le plafond d'un attribut n'est plus le même pour tout le monde : 90 pour tout le
        // monde interdisait les joueurs d'exception, et cent carrières finissaient par se
        // ressembler par le haut. Il dépend du palier de talent, des étoiles achetées et
        // d'un tirage — seul un talent de génération avec des étoiles approche les 99.
        let attributeCeiling = min(99, 86 + Int.random(in: 0...4) + talent.potentialBias / 2
                                   + halfBought / 2 - halfHandicap)
        var potential: [String: Int] = [:]
        for a in FDAttribute.allCases {
            let base = attrs[a.rawValue] ?? 22
            let spread = Int.random(in: (potBias - 8)...(potBias + 18)) + Int((Double(talentSeed) * 0.8).rounded())
            potential[a.rawValue] = min(max(base + spread, base + 6), attributeCeiling)
        }

        let startMoney: Int
        switch draft.background {
        case .aisee: startMoney = 6000
        case .footballeur: startMoney = 3500
        default: startMoney = 1200
        }

        var newPlayer = FDPlayer(
            firstName: draft.firstName, lastName: draft.lastName, nationality: draft.nationality, birthCity: draft.birthCity,
            foot: draft.foot, position: draft.position, personality: draft.personality, style: draft.style,
            background: draft.background, difficulty: draft.difficulty, mode: draft.mode,
            age: 16, status: .pro, club: club,
            attrs: attrs, potential: potential,
            cond: FDCondition(
                forme: min(100, 62 + competenceForme), moral: min(100, 65 + competenceMoral), fatigue: 15,
                confiance: min(100, 52 + competenceConfiance), reputation: min(100, 4 + competenceReputation)
            ),
            rel: FDRelations(),
            money: startMoney + competenceMoney,
            contract: FDContract(salary: 300, years: 0),
            calendar: FDCalendar(season: 1, week: 0, seasonWeeks: 38)
        )
        newPlayer.talentTier = talent.id
        // Ce qui rend cette carrière-là unique, au-delà des étoiles et du palier de talent :
        // son rythme — régulière ou faite de trous d'air et de flambées — et sa main devant
        // le but. Tirés ici une fois pour toutes, jamais annoncés.
        newPlayer.startHalfStars = halfStars
        newPlayer.careerVolatility = Double.random(in: 0.55...1.6)
        newPlayer.finishingEdge = Double.random(in: -0.045...0.06)
        newPlayer.originClubId = club.id
        newPlayer.journal.insert(FDJournalEntry(week: 0, season: 1, age: 16, text: "Débuts professionnels chez \(club.name) à 16 ans.", icon: "⚽"), at: 0)

        let rivalName = FDNameBank.random(for: draft.nationality)
        newPlayer.rivalFirstName = rivalName.first
        newPlayer.rivalLastName = rivalName.last
        newPlayer.rivalMomentum = Int.random(in: 40...60)

        newPlayer.clubObjective = generateClubObjective(newPlayer)
        newPlayer.personalObjective = generatePersonalObjective(newPlayer)

        player = newPlayer
        usedSceneIds = []
        sceneCooldown = [:]
        currentScene = generateNextEvent()
        autoResolveExpress()
        saveGame()
    }

    // MARK: - Creation-choice attribute bonuses
    // Every card picked during creation nudges the starting roll in a small, thematic way,
    // on top of the position weights that already shape the bulk of the distribution.

    private func styleBonus(_ style: FDStyle, category: FDAttrCategory) -> Int {
        switch (style, category) {
        case (.technicien, .tech), (.createur, .tech), (.finisseur, .tech): return 4
        case (.rapide, .phys), (.puissant, .phys): return 4
        case (.recuperateur, .def): return 4
        case (.leader, .ment): return 4
        case (.createur, .ment): return 2
        default: return 0
        }
    }

    private func personalityBonus(_ personality: FDPersonality, category: FDAttrCategory) -> Int {
        guard category == .ment else { return 0 }
        switch personality {
        case .ambitieux, .travailleur, .discipline: return 3
        case .reserve: return 2
        case .charismatique, .provocateur: return 1
        case .irregulier: return 0
        }
    }

    private func backgroundBonus(_ background: FDBackground, category: FDAttrCategory) -> Int {
        switch background {
        case .footballeur: return (category == .tech || category == .ment) ? 3 : 0
        case .aisee: return category == .phys ? 2 : 0
        case .modeste: return category == .ment ? 2 : 0
        case .stable: return 0
        }
    }

    private func footBonus(_ foot: FDFoot, category: FDAttrCategory) -> Int {
        guard category == .tech else { return 0 }
        switch foot {
        case .droit, .gauche: return 1
        case .ambidextre: return 3
        }
    }

    // MARK: - Trait effects

    private func traitRatingModifier(_ p: FDPlayer) -> Double {
        var bonus = 0.0
        if p.traits.contains(.leaderNe) { bonus += 0.08 }
        if p.traits.contains(.guerrier) { bonus += 0.05 }
        if p.traits.contains(.talentBrut) { bonus += Double.random(in: -0.18...0.22) }
        return bonus
    }

    // MARK: - Lifetime meta-progression

    @discardableResult
    private func awardLifetimePoints(for p: FDPlayer) -> Int {
        var earned = max(
            5,
            p.careerGoals * 2 + p.careerAssists + p.careerApps / 3
                + p.cond.reputation / 5 + max(0, p.calendar.season - 1) * 3
        )
        // Une carrière lancée sous les deux étoiles a tout fait plus dur : plafond plus bas,
        // meilleurs paliers de talent plus rares, division de départ plus basse. Elle rapporte
        // donc davantage — quinze pour cent par demi-étoile abandonnée, soit soixante pour
        // cent à zéro étoile. C'est le seul moyen de gagner vite sans dépenser.
        let handicap = max(0, FDPotentialShop.freeHalfStars - (p.startHalfStars ?? FDPotentialShop.freeHalfStars))
        if handicap > 0 {
            earned = Int((Double(earned) * (1 + 0.15 * Double(handicap))).rounded())
        }
        lifetimePoints += earned
        UserDefaults.standard.set(lifetimePoints, forKey: Self.lifetimePointsKey)
        return earned
    }

    /// 1-14 "pièces" — the Boutique and the Défis are priced against this, so the spread
    /// matters: a career that just ran its course banks 1-2, a solid one 3-5, and only a
    /// genuinely exceptional run (Ballon d'Or, international title, repeated silverware)
    /// approaches the ceiling. See FDMetaProgression for how the price bands map to this.
    private func careerQualityCoins(for p: FDPlayer) -> Int {
        var score = 1  // finishing a career at all is worth something

        let ballons = p.awardCounts[FDAward.ballonDor.rawValue] ?? 0
        let souliers = p.awardCounts[FDAward.soulierDor.rawValue] ?? 0
        let internationals = p.awardCounts["Titre international"] ?? 0

        score += min(4, ballons * 2)
        score += min(2, souliers)
        score += min(3, internationals * 2)
        score += min(2, p.leagueTitles)
        score += min(2, p.cupTitles)

        if p.careerGoals >= 100 { score += 1 }
        if p.careerGoals >= 200 { score += 1 }
        if p.cond.reputation >= 70 { score += 1 }
        if p.cond.reputation >= 88 { score += 1 }
        if p.nationalCaps >= 50 { score += 1 }

        return min(14, score)
    }

    // MARK: - Leaderboard
    //
    // There is no account and no server, so this is a local hall of fame: every career
    // finished on this device, ranked against each other. Ordering follows the weight the
    // game gives each achievement — Ballon d'Or first, then international titles, league
    // and cup silverware, then caps and raw output.

    /// Ranking score for the leaderboard, in the order the game values achievements:
    ///
    ///  1. Ballon d'Or — the individual summit, worth more than anything else.
    ///  2. International titles (world/continental), then European club silverware.
    ///  3. Domestic league and cup titles.
    ///  4. Individual output, weighted **by position** so the four roles compete fairly:
    ///     a striker is judged on goals, a midfielder on assists and rating, a defender
    ///     and a keeper on rating and longevity. Without this a striker would always
    ///     outrank a defender on raw goal count alone.
    func careerRankScore(_ p: FDPlayer) -> Int {
        let ballon = p.awardCounts[FDAward.ballonDor.rawValue] ?? 0
        let soulier = p.awardCounts[FDAward.soulierDor.rawValue] ?? 0
        let international = p.awardCounts["Titre international"] ?? 0
        let revelation = p.awardCounts[FDAward.revelation.rawValue] ?? 0

        // --- Honours, identical for every position ---
        var score = ballon * 600
            + international * 400
            + p.cupTitles * 130      // European / cup silverware
            + p.leagueTitles * 110
            + soulier * 150
            + revelation * 40
            + p.nationalCaps * 3

        // --- Individual output, balanced per position ---
        let seasons = max(p.history.count, 1)
        let avgRating = p.history.isEmpty
            ? 0.0
            : p.history.reduce(0.0) { $0 + $1.avgRating } / Double(p.history.count)
        // A 7.0 average is par; every tenth of a point above it is worth real weight.
        let ratingPoints = Int(max(0.0, avgRating - 6.0) * 60)

        switch p.position {
        case .attaquant:
            score += p.careerGoals * 3 + p.careerAssists + ratingPoints
        case .milieu:
            score += p.careerAssists * 3 + p.careerGoals + ratingPoints * 2
        case .defenseur:
            score += ratingPoints * 3 + p.careerApps / 2 + p.careerGoals * 2 + p.careerAssists
        case .gardien:
            score += ratingPoints * 3 + p.careerApps / 2
        }

        // Longevity at a good level counts a little for everyone.
        score += seasons * 10 + p.cond.reputation

        return score
    }


    /// Archived careers ranked best-first, capped at the top 100.
    ///
    /// Money never adds to the score — two careers are separated by what they won. It only
    /// breaks a tie: at equal score, the wealthier band goes first, then the exact fortune.
    var leaderboard: [FDPlayer] {
        archivedCareers
            .sorted { a, b in
                let sa = careerRankScore(a), sb = careerRankScore(b)
                if sa != sb { return sa > sb }
                let wa = FDWealthScale.points(for: a.money), wb = FDWealthScale.points(for: b.money)
                if wa != wb { return wa > wb }
                return a.money > b.money
            }
            .prefix(100)
            .map { $0 }
    }

    /// Sets the handle on the most recently finished career and re-persists the archive.
    func setAliasForLatestCareer(_ alias: String) {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !archivedCareers.isEmpty else { return }
        archivedCareers[0].alias = String(trimmed.prefix(18))
        if let data = try? JSONEncoder().encode(archivedCareers) {
            UserDefaults.standard.set(data, forKey: Self.archiveKey)
        }
    }

    /// A larger composite score used to compare a career against a Défi Gloire du Passé target.
    private func legendScore(for p: FDPlayer) -> Int {
        p.careerGoals * 2 + p.careerAssists + p.leagueTitles * 15 + p.cupTitles * 10
            + (p.awardCounts[FDAward.ballonDor.rawValue] ?? 0) * 40
            + (p.awardCounts[FDAward.soulierDor.rawValue] ?? 0) * 25
            + (p.awardCounts["Titre international"] ?? 0) * 35
            + p.nationalCaps
    }

    /// Called on every retirement path: banks legend coins, archives the finished career for
    /// the Historique, and — if this was a Défi Gloire du Passé attempt — checks it against target.
    private func archiveRetiredCareer(_ p: FDPlayer) {
        archivedCareers.insert(p, at: 0)
        if archivedCareers.count > 200 { archivedCareers.removeLast(archivedCareers.count - 200) }
        if let data = try? JSONEncoder().encode(archivedCareers) {
            UserDefaults.standard.set(data, forKey: Self.archiveKey)
        }

        let coins = careerQualityCoins(for: p)
        legendCoins += coins
        UserDefaults.standard.set(legendCoins, forKey: Self.legendCoinsKey)

        if let challengeID = activeLegendChallengeID {
            if let challenge = FDLegendChallenges.first(where: { $0.id == challengeID }),
               legendScore(for: p) >= challenge.targetScore {
                conqueredLegendIDs.insert(challengeID)
                UserDefaults.standard.set(Array(conqueredLegendIDs), forKey: Self.conqueredLegendsKey)
            }
            activeLegendChallengeID = nil
        }
    }

    // MARK: - Boutique & Défi Gloire du Passé

    /// Buys one career's worth of a competence at the base price. Charges stack, so the
    /// player can stock several runs of the same perk.
    @discardableResult
    func purchaseCompetenceCharge(_ id: String) -> Bool {
        guard let competence = FDCompetences.first(where: { $0.id == id }),
              !ownedCompetenceIDs.contains(id),
              legendCoins >= competence.cost else { return false }
        legendCoins -= competence.cost
        competenceCharges[id, default: 0] += 1
        persistCompetences()
        return true
    }

    /// Buys a competence outright at five times the base price — from then on it can be
    /// equipped in every career without spending a charge.
    @discardableResult
    func purchaseCompetencePermanently(_ id: String) -> Bool {
        guard let competence = FDCompetences.first(where: { $0.id == id }),
              !ownedCompetenceIDs.contains(id),
              legendCoins >= competence.permanentCost else { return false }
        legendCoins -= competence.permanentCost
        ownedCompetenceIDs.insert(id)
        competenceCharges[id] = nil   // charges are redundant once it's owned for good
        persistCompetences()
        return true
    }

    private func persistCompetences() {
        UserDefaults.standard.set(legendCoins, forKey: Self.legendCoinsKey)
        UserDefaults.standard.set(Array(ownedCompetenceIDs), forKey: Self.ownedCompetencesKey)
        UserDefaults.standard.set(competenceCharges, forKey: Self.chargesKey)
    }

    /// Everything the player could bring into a new career: owned outright, or with at
    /// least one unused single-career charge.
    var equippableCompetences: [FDCompetence] {
        FDCompetences.filter { ownedCompetenceIDs.contains($0.id) || (competenceCharges[$0.id] ?? 0) > 0 }
    }

    /// How many careers this competence is still good for — nil when owned outright.
    func remainingCharges(_ id: String) -> Int? {
        ownedCompetenceIDs.contains(id) ? nil : competenceCharges[id]
    }

    @discardableResult
    func unlockLegendChallenge(_ id: String) -> Bool {
        guard let challenge = FDLegendChallenges.first(where: { $0.id == id }), !unlockedLegendIDs.contains(id), legendCoins >= challenge.unlockCost else { return false }
        legendCoins -= challenge.unlockCost
        unlockedLegendIDs.insert(id)
        UserDefaults.standard.set(legendCoins, forKey: Self.legendCoinsKey)
        UserDefaults.standard.set(Array(unlockedLegendIDs), forKey: Self.unlockedLegendsKey)
        return true
    }

    /// Starts a career preset toward a legend's archetype (nationality/poste/style/personnalité) —
    /// the player still writes their own story, but the odds and the target are the legend's.
    func startLegendCareer(_ challenge: FDLegendChallenge) {
        var draft = FDCreationDraft()
        draft.nationality = challenge.nationality
        draft.position = challenge.position
        draft.style = challenge.style
        draft.personality = challenge.personality
        let generated = FDNameBank.random(for: challenge.nationality)
        draft.firstName = generated.first
        draft.lastName = generated.last

        let homeClubs = FDAllClubs.filter { $0.country == challenge.nationality }.sorted { $0.academyQuality > $1.academyQuality }
        guard let club = homeClubs.first ?? FDAllClubs.randomElement() else { return }

        startCareer(draft: draft, club: club, legendChallengeID: challenge.id)
    }

    // MARK: - Compatibility aliases (redesigned Boutique/Défis screens)

    var permanentSkills: [FDCompetence] { FDCompetences }
    var unlockedSkills: Set<String> { ownedCompetenceIDs }

    var challenges: [FDLegendChallenge] { FDLegendChallenges }
    var conqueredChallenges: Set<String> { conqueredLegendIDs }
    var unlockedChallenges: Set<String> { unlockedLegendIDs }
    func unlockChallenge(_ challenge: FDLegendChallenge) { unlockLegendChallenge(challenge.id) }
    func startChallenge(_ challenge: FDLegendChallenge) { startLegendCareer(challenge) }

    /// La division où l'on atterrit en moyenne, pour un total d'étoiles donné — offertes
    /// comprises. Deux étoiles, c'est la deuxième division : le niveau où un jeune pro joue
    /// vraiment. Chaque étoile achetée par-dessus rapproche de l'élite.
    private func baseCentralDivision(totalStars: Double) -> Int {
        if totalStars >= 3 { return 1 }
        if totalStars >= 2 { return 2 }
        if totalStars >= 1 { return 3 }
        return 4
    }

    /// La même chose, ramenée à ce que le pays offre réellement : tous les championnats ne
    /// sont pas modélisés aussi profond que la France, et il ne faudrait pas annoncer une
    /// deuxième division à un joueur d'un pays qui n'en a pas.
    func startCentralDivision(nationality: String, totalStars: Double) -> Int {
        let deepest = FDAllClubs.filter { $0.country == nationality }.map(\.division).max() ?? 1
        return min(baseCentralDivision(totalStars: totalStars), deepest)
    }

    private func startDivisions(centre: Int) -> ClosedRange<Int> {
        max(1, centre - 1)...min(4, centre + 1)
    }

    /// Les six portes ouvertes au tout début, `totalStars` étant les étoiles offertes plus
    /// celles achetées. On ne propose pas un bloc de clubs équivalents : la moitié au niveau
    /// moyen du joueur, un cran au-dessus pour ceux qui veulent que ce soit dur tout de suite,
    /// un cran en dessous pour ceux qui préfèrent jouer et progresser tranquillement.
    /// Le tirage n'est fait qu'une fois par écran : sans ce cache, la liste se rebattrait à
    /// chaque redessin de la vue et le club sélectionné sauterait d'une ligne à l'autre. Elle
    /// se rejoue quand la nationalité ou les étoiles changent, et au lancement de la carrière
    /// suivante.
    private var startClubCacheKey = ""
    private var startClubCache: [FDClub] = []

    func availableStartClubs(nationality: String, potentialStars totalStars: Double) -> [FDClub] {
        let key = "\(nationality)#\(totalStars)"
        if key == startClubCacheKey, !startClubCache.isEmpty { return startClubCache }
        let picks = buildStartClubs(nationality: nationality, totalStars: totalStars)
        startClubCacheKey = key
        startClubCache = picks
        return picks
    }

    private func buildStartClubs(nationality: String, totalStars: Double) -> [FDClub] {
        let centre = startCentralDivision(nationality: nationality, totalStars: totalStars)
        let allowed = startDivisions(centre: centre)
        let home = FDAllClubs.filter { $0.country == nationality }

        // Si le pays n'est pas modélisé aussi profond, on élargit plutôt que de rendre une
        // liste vide : mieux vaut une division voisine qu'un écran sans club.
        var pool = home.filter { allowed.contains($0.division) }
        if pool.count < 5 {
            let deepest = home.map(\.division).max() ?? 1
            let fallback = min(allowed.lowerBound, deepest)
            pool = home.filter { $0.division >= fallback }
        }
        if pool.isEmpty { pool = home }

        // On tire au sort dans les meilleurs candidats plutôt que de prendre les mêmes en
        // tête de liste : quelqu'un qui lance cent carrières se voyait proposer six fois le
        // même club de départ. Le vivier reste cohérent — les bonnes formations pour qui a
        // des étoiles, les clubs modestes pour qui veut jouer tout de suite — mais qui en
        // sort change à chaque fois.
        func band(_ division: Int, _ count: Int, best: Bool) -> [FDClub] {
            let clubs = pool.filter { $0.division == division }
            guard !clubs.isEmpty else { return [] }
            let sorted = best
                ? clubs.sorted { $0.academyQuality > $1.academyQuality }
                : clubs.sorted { $0.reputation < $1.reputation }
            // Deux fois plus de candidats que de places, plus une marge : le tirage a de quoi
            // varier sans jamais descendre dans le fond du panier.
            let vivier = Array(sorted.prefix(max(count * 3, count + 4)))
            return Array(vivier.shuffled().prefix(count))
        }

        // À quatre étoiles et plus, on n'entre plus par la petite porte : les six clubs
        // proposés jouent le haut du tableau et la carrière démarre déjà lancée.
        if totalStars >= 4 {
            let elite = pool.filter { $0.division == centre }.sorted { $0.reputation > $1.reputation }
            if elite.count >= 4 { return Array(elite.prefix(10).shuffled().prefix(6)) }
        }

        // Un cran au-dessus (plus dur), le niveau moyen, un cran en dessous (plus de jeu).
        // Quand le niveau moyen est déjà l'élite, il n'y a rien au-dessus : la place revient
        // au niveau moyen lui-même.
        let aboveCount = centre > 1 ? 1 : 0
        var picks = band(centre - 1, aboveCount, best: true)
        picks += band(centre, 3 + (1 - aboveCount), best: true)
        picks += band(centre + 1, 2, best: false)

        // Compléter si une division manque dans ce pays, sans jamais doublonner.
        if picks.count < 6 {
            let taken = Set(picks.map(\.id))
            picks += pool
                .filter { !taken.contains($0.id) }
                .sorted { $0.academyQuality > $1.academyQuality }
                .prefix(10)
                .shuffled()
                .prefix(6 - picks.count)
        }
        return picks.sorted { $0.division < $1.division }
    }

    /// Convenience overload for the redesigned creation flow, which stores the chosen club
    /// directly on the draft instead of passing it as a separate argument.
    func startCareer(from draft: FDCreationDraft) {
        guard let club = draft.club else { return }
        // La prochaine création rejouera son tirage de clubs de départ.
        startClubCacheKey = ""
        startClubCache = []
        startCareer(draft: draft, club: club)
    }

    // MARK: - Derived stats

    func overall(_ p: FDPlayer) -> Int {
        let w = p.position.weights
        var byCat: [FDAttrCategory: [Int]] = [.tech: [], .phys: [], .ment: [], .def: []]
        for a in FDAttribute.allCases { byCat[a.category, default: []].append(p.attr(a)) }
        let avg: (FDAttrCategory) -> Double = { c in
            let arr = byCat[c] ?? []
            return arr.isEmpty ? 0 : Double(arr.reduce(0, +)) / Double(arr.count)
        }
        let v = avg(.tech) * w.tech + avg(.phys) * w.phys + avg(.ment) * w.ment + avg(.def) * w.def
        return Int(v.rounded())
    }

    func potentialOverall(_ p: FDPlayer) -> Int {
        let w = p.position.weights
        var byCat: [FDAttrCategory: [Int]] = [.tech: [], .phys: [], .ment: [], .def: []]
        for a in FDAttribute.allCases { byCat[a.category, default: []].append(p.potential(a)) }
        let avg: (FDAttrCategory) -> Double = { c in
            let arr = byCat[c] ?? []
            return arr.isEmpty ? 0 : Double(arr.reduce(0, +)) / Double(arr.count)
        }
        let v = avg(.tech) * w.tech + avg(.phys) * w.phys + avg(.ment) * w.ment + avg(.def) * w.def
        return Int(v.rounded())
    }

    func marketValue(_ p: FDPlayer) -> Int {
        let ovr = Double(overall(p))
        let ageFactor: Double = p.age <= 23 ? 1.1 : (p.age <= 29 ? 1.3 : (p.age <= 33 ? 0.8 : 0.3))
        let base = pow(max(ovr - 30, 1), 2.05) * 260 * ageFactor
        let repFactor = 1 + Double(p.cond.reputation) / 150
        let raw = (base * repFactor / 1000).rounded() * 1000
        return min(95_000_000, Int(raw))
    }

    private func ageGrowthFactor(_ age: Int) -> Double {
        if age <= 20 { return 1.4 }
        if age <= 25 { return 1.0 }
        if age <= 29 { return 0.5 }
        if age <= 33 { return 0.05 }
        return -0.6
    }

    // MARK: - Journal / toast

    private func pushJournal(_ text: String, icon: String = "📌") {
        guard var p = player else { return }
        p.journal.insert(FDJournalEntry(week: p.calendar.week, season: p.calendar.season, age: p.age, text: text, icon: icon), at: 0)
        if p.journal.count > 300 { p.journal.removeLast(p.journal.count - 300) }
        player = p
    }

    private func showToast(_ message: String) {
        guard !suppressToast else { return }
        toastDismissWorkItem?.cancel()
        toast = message
        let work = DispatchWorkItem { [weak self] in self?.toast = nil }
        toastDismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: work)
    }

    // MARK: - Effects

    private func condLabel(_ key: String) -> String {
        switch key {
        case "forme": return "Forme"
        case "moral": return "Moral"
        case "fatigue": return "Fatigue"
        case "confiance": return "Confiance"
        case "reputation": return "Réputation"
        default: return key.capitalized
        }
    }

    /// Applies stat/condition/relation/money deltas and returns them as display-ready pills —
    /// the caller decides whether/how to reveal them (never before a choice is made).
    @discardableResult
    private func applyEffects(_ effects: [FDEffect]) -> [FDEffectPill] {
        guard var p = player else { return [] }
        var pills: [FDEffectPill] = []
        for e in effects {
            if let attr = e.attr {
                let before = p.attr(attr)
                let cap = p.potential(attr) + 2
                let newVal = min(max(before + e.delta, 0), cap)
                p.attrs[attr.rawValue] = newVal
                if e.delta != 0 {
                    pills.append(FDEffectPill(label: attr.label, valueText: "\(e.delta > 0 ? "+" : "")\(e.delta)", positive: e.delta > 0))
                }
            }
            if let condKey = e.cond {
                let before = p.condition(condKey)
                let newVal = min(max(before + e.delta, 0), 100)
                switch condKey {
                case "forme": p.cond.forme = newVal
                case "moral": p.cond.moral = newVal
                case "fatigue": p.cond.fatigue = newVal
                case "confiance": p.cond.confiance = newVal
                case "reputation": p.cond.reputation = newVal
                default: break
                }
                if e.delta != 0 {
                    pills.append(FDEffectPill(label: condLabel(condKey), valueText: "\(e.delta > 0 ? "+" : "")\(e.delta)", positive: e.delta > 0))
                }
            }
            if let relKey = e.rel {
                let before = p.relation(relKey)
                let newVal = min(max(before + e.delta, 0), 100)
                switch relKey {
                case "coach": p.rel.coach = newVal
                case "staff": p.rel.staff = newVal
                case "directeur": p.rel.directeur = newVal
                case "president": p.rel.president = newVal
                case "agent": p.rel.agent = newVal
                case "capitaine": p.rel.capitaine = newVal
                case "vestiaire": p.rel.vestiaire = newVal
                case "famille": p.rel.famille = newVal
                case "partenaire": p.rel.partenaire = newVal
                case "media": p.rel.media = newVal
                case "fans": p.rel.fans = newVal
                default: break
                }
            }
            if let money = e.money {
                p.money = max(0, p.money + money)
                p.seasonMoneyDelta += money
                if money != 0 {
                    pills.append(FDEffectPill(label: "Argent", valueText: "\(money > 0 ? "+" : "-")\(fdFormatMoney(abs(money)))", positive: money > 0))
                }
            }
        }
        player = p
        return pills
    }

    // MARK: - Match simulation

    /// Le niveau de l'adversaire dépend du championnat et du club, jamais du joueur. C'était
    /// le défaut du modèle précédent : l'adversaire suivait la progression du joueur, donc
    /// plus on devenait fort, plus on affrontait fort, et une star mondiale finissait la
    /// saison avec la même note et le même total de buts qu'un titulaire de deuxième
    /// division. Maintenant, progresser se voit.
    private func opponentLevel(_ p: FDPlayer) -> Int {
        let divisionBase: Double
        switch p.club.division {
        case 1: divisionBase = 66
        case 2: divisionBase = 54
        case 3: divisionBase = 44
        default: divisionBase = 36
        }
        let base = divisionBase * 0.62 + Double(p.club.reputation) * 0.38
        return min(max(Int((base + Double(Int.random(in: -12...12))).rounded()), 15), 95)
    }

    /// La chance d'être titulaire, en clair : l'écart entre son niveau et le standard du
    /// club, la confiance du coach et du président, le niveau absolu, l'âge et le statut.
    /// Rien n'est acquis d'une saison à l'autre — c'est ce chiffre qui fait qu'on joue
    /// trente matchs ou qu'on en regarde vingt.
    func startChance(_ p: FDPlayer) -> Double {
        let ovr = Double(overall(p))
        let trust = Double(p.rel.coach) * 0.7 + Double(p.rel.president) * 0.3
        var chance = 0.45 + (ovr - Double(p.club.reputation)) / 40 + (trust - 50) / 100
            + (ovr - 70) / 200 + Double(p.club.youthMinutes) / 500
        if p.status == .reserve { chance -= 0.22 }
        if p.age >= 34 { chance -= 0.12 }
        // Un club ne juge pas un gamin comme un joueur confirmé : à vingt ans on joue sur la
        // promesse. C'est ce qui rend jouable un départ dans un grand club — on y grappille
        // des bouts de match au lieu d'y disparaître — sans rendre le choix gratuit : à ce
        // temps de jeu-là, on progresse deux fois moins vite qu'un titulaire ailleurs.
        if p.age <= 20 { chance = max(chance, 0.18 + Double(p.club.youthMinutes) / 400) }
        return min(max(chance, 0.02), 0.95)
    }

    private func willStart(_ p: FDPlayer) -> Bool {
        Double.random(in: 0...1) < startChance(p)
    }

    /// L'année qu'un joueur est en train de vivre devant le but. La plupart du temps elle ne
    /// dit rien de particulier ; parfois plus rien ne rentre ; et très rarement, tout rentre —
    /// c'est cette saison-là qui permet à une superstar de finir à cinquante buts.
    ///
    /// Rien n'est fixé d'avance : le tirage est fait à neuf chaque saison, et même ses
    /// probabilités dépendent de la carrière. Une carrière régulière ne connaîtra presque
    /// jamais d'extrême ; une carrière cyclique enchaînera les trous d'air et les flambées.
    /// Le multiplicateur lui-même est tiré dans une fourchette, donc deux années de légende
    /// ne se ressemblent pas davantage que deux carrières.
    private func drawSeasonMood(_ p: FDPlayer) -> Double {
        let volatility = p.careerVolatility ?? 1.0
        let talent = fdTalentTier(p.talentTier)
        let legendary = 0.025 * volatility * (talent.growthFactor >= 1.15 ? 2.0 : 1.0)
        let good = 0.09 + 0.07 * volatility
        let blank = 0.09 + 0.06 * volatility
        let roll = Double.random(in: 0...1)
        if roll < legendary { return Double.random(in: 1.42...1.78) }
        if roll < legendary + good { return Double.random(in: 1.10...1.34) }
        if roll > 1 - blank { return Double.random(in: 0.60...0.88) }
        return Double.random(in: 0.90...1.10)
    }

    /// Quand il ne commence pas, entre-t-il en cours de match ? Là encore la confiance
    /// décide : un joueur que le coach a lâché ne rentre même plus.
    private func benchAppearanceChance(_ p: FDPlayer) -> Double {
        let trust = Double(p.rel.coach) * 0.7 + Double(p.rel.president) * 0.3
        return min(0.7, max(0.04, 0.15 + (trust - 30) / 150))
    }

    /// `forceStart` sert au grand rendez-vous : la scène vient de raconter que le joueur était
    /// sur le terrain et ce qu'il y a fait, le match ne peut donc pas répondre qu'il n'est
    /// jamais entré. C'était le défaut le plus visible du récit d'après-match — le texte du
    /// choix disait « c'est de là qu'est venu le but », l'article disait « il n'est pas entré ».
    private func simulateMatch(forceStart: Bool = false) -> FDMatchResult {
        guard var p = player else {
            return FDMatchResult(started: false, minutes: 0, rating: 0, goals: 0, assists: 0, yellow: false, red: false, injury: false, teamScore: 0, oppScore: 0, opponentLevel: 0)
        }
        let ovr = Double(overall(p))
        let opp = opponentLevel(p)
        let started = forceStart || willStart(p)
        let minutes = started
            ? Int.random(in: 60...90)
            : (Double.random(in: 0...1) < benchAppearanceChance(p) ? Int.random(in: 5...30) : 0)

        var rating = 5.7 + (ovr - Double(opp)) / 18 + (Double(p.cond.forme) - 50) / 60 + (Double(p.cond.confiance) - 50) / 90 + Double(Int.random(in: -9...9)) / 10
        rating += traitRatingModifier(p)
        rating = minutes > 0 ? min(max(rating, 3.0), 10.0) : 0

        let yellow = minutes > 0 && Double.random(in: 0...1) < (0.06 + Double(p.attr(.force)) / 900)
        let red = yellow && Double.random(in: 0...1) < 0.05
        var injury = false
        if minutes > 0 && Double.random(in: 0...1) < (0.02 + Double(p.cond.fatigue) / 1400) { injury = true }

        // Le résultat est d'abord celui d'une équipe : la réputation du club pèse trois fois
        // plus que le niveau du joueur, qui n'est qu'un homme sur onze.
        let teamStrength = Double(p.club.reputation) * 0.75 + ovr * 0.25
        let teamScore = min(max(Int.random(in: 0...3) + (teamStrength > Double(opp) ? 1 : 0) - (teamStrength < Double(opp) - 15 ? 1 : 0), 0), 6)
        let oppScore = min(max(Int.random(in: 0...3) - (teamStrength > Double(opp) + 10 ? 1 : 0) + (teamStrength < Double(opp) - 10 ? 1 : 0), 0), 6)

        // Les buts du joueur se prennent sur ceux de son équipe, but par but : on ne marque
        // pas un doublé dans une défaite 1-0, et un 4-0 laisse la place à un triplé. Un
        // attaquant titulaire et en forme repart avec une vraie ligne de statistiques —
        // l'ancienne formule lui donnait quatre buts par saison, feuille de match vide.
        var goals = 0, assists = 0
        if minutes > 0 && teamScore > 0 {
            let share = min(1.0, Double(minutes) / 75.0)
            // La main du joueur devant le but, propre à sa carrière, et l'humeur de l'année,
            // tirée au premier match puis gardée jusqu'au bilan : on sent qu'on est dedans,
            // ou qu'on ne l'est pas, et ça dure toute la saison.
            let sharpness = p.finishingEdge ?? 0
            if p.seasonMood == nil { p.seasonMood = drawSeasonMood(p) }
            let mood = p.seasonMood ?? 1.0
            let scorer: Double
            let passer: Double
            switch p.position {
            case .attaquant:
                scorer = 0.07 + sharpness + (rating - 6) * 0.095 + (Double(p.attr(.tir)) - 55) / 280
                passer = 0.10 + (Double(p.attr(.passe)) - 60) / 900
            case .milieu:
                scorer = 0.03 + sharpness * 0.6 + (rating - 6) * 0.05 + (Double(p.attr(.tir)) - 55) / 500
                passer = 0.20 + (rating - 6) * 0.03 + (Double(p.attr(.passe)) - 60) / 600
            case .defenseur:
                scorer = 0.02 + (rating - 6) * 0.012
                passer = 0.07 + (Double(p.attr(.passe)) - 60) / 1100
            case .gardien:
                scorer = 0
                passer = 0.01
            }
            for _ in 0..<teamScore {
                if Double.random(in: 0...1) < max(0, min(0.76, scorer * mood)) * share {
                    goals += 1
                } else if Double.random(in: 0...1) < max(0, min(0.5, passer * mood)) * share {
                    assists += 1
                }
            }
        }

        // La journée a eu lieu pour le club, que le joueur soit entré ou non : c'est ce qui
        // permet de juger une saison en part de temps de jeu plutôt qu'en nombre de matchs.
        p.seasonFixtures = (p.seasonFixtures ?? 0) + 1

        if minutes > 0 {
            p.cond.fatigue = min(max(p.cond.fatigue + Int((Double(minutes) / 7).rounded()), 0), 100)
            p.cond.forme = min(max(p.cond.forme + Int(((rating - 6) * 1.0).rounded()), 0), 100)
            p.cond.confiance = min(max(p.cond.confiance + Int(((rating - 6) * 1.2).rounded()), 0), 100)
            p.rel.coach = min(max(p.rel.coach + (rating >= 7 ? 2 : (rating < 5 ? -2 : 0)), 0), 100)
            // Une réputation se construit sur des saisons, pas sur deux mois : maintenant
            // qu'on joue une trentaine de matchs par an, les anciens gains par match
            // auraient mis le compteur à 100 avant Noël. Et plus on est haut, plus ça freine.
            var repGain = (rating >= 7.5 ? 1 : 0) + goals + (assists > 0 ? 1 : 0)
            if p.cond.reputation >= 70 { repGain = (repGain + 1) / 2 }
            p.cond.reputation = min(max(p.cond.reputation + repGain, 0), 100)
            p.seasonMatches += 1; p.seasonGoals += goals; p.seasonAssists += assists
            p.careerApps += 1; p.careerGoals += goals; p.careerAssists += assists
            p.seasonForm.append(rating)
            if injury {
                p.cond.forme = min(max(p.cond.forme - 18, 0), 100)
                p.cond.fatigue = min(max(p.cond.fatigue + 20, 0), 100)
            }
        } else {
            p.cond.fatigue = min(max(p.cond.fatigue - 4, 0), 100)
            p.cond.confiance = min(max(p.cond.confiance - 2, 0), 100)
        }
        player = p

        return FDMatchResult(started: started, minutes: minutes, rating: rating, goals: goals, assists: assists,
                              yellow: yellow, red: red, injury: injury, teamScore: teamScore, oppScore: oppScore, opponentLevel: opp)
    }

    // MARK: - Turn engine

    private func sceneEligible(_ s: FDSceneDef, player p: FDPlayer) -> Bool {
        if s.once && usedSceneIds.contains(s.id) { return false }
        let key = p.calendar.week + p.calendar.season * 100
        if let cooldown = sceneCooldown[s.id], cooldown > key { return false }
        if p.age < s.minAge || p.age > s.maxAge { return false }
        if let statuses = s.statuses, !statuses.contains(p.status) { return false }
        if let positions = s.positions, !positions.contains(p.position) { return false }
        // Legend scenes only exist inside a "Gloire du Passé" run.
        if s.legendOnly && activeLegendChallengeID == nil { return false }
        if let cond = s.condition, !cond(p) { return false }
        return true
    }

    /// Scene text/character can reference "{rival}" — swapped for the player's persistent
    /// rival's last name at pick time so hand-written Rivalité scenes stay dynamic.
    private func personalize(_ text: String, player p: FDPlayer) -> String {
        var out = text
        if out.contains("{rival}") {
            let name = p.rivalLastName.isEmpty ? "ton rival" : p.rivalLastName
            out = out.replacingOccurrences(of: "{rival}", with: name)
        }
        // Legend challenge scenes speak of the player being chased, by name, era and post.
        if out.contains("{legend}") || out.contains("{legendEra}") || out.contains("{legendPoste}") {
            let legend = activeLegendChallengeID.flatMap { id in
                FDLegendChallenges.first(where: { $0.id == id })
            }
            out = out.replacingOccurrences(of: "{legend}", with: legend?.name ?? "la légende")
            out = out.replacingOccurrences(of: "{legendEra}", with: legend?.era.lowercased() ?? "l'époque")
            out = out.replacingOccurrences(of: "{legendPoste}", with: legend?.position.rawValue.lowercased() ?? "joueur")
        }
        // Les rendez-vous parlent du club, du pays et de l'état d'esprit du moment : la même
        // scène ne sonne pas pareil selon qu'on la traverse gonflé à bloc ou la tête ailleurs.
        out = out.replacingOccurrences(of: "{club}", with: p.club.name)
        out = out.replacingOccurrences(of: "{pays}", with: p.nationality)
        out = out.replacingOccurrences(of: "{ville}", with: p.birthCity)
        if out.contains("{humeur}") {
            out = out.replacingOccurrences(of: "{humeur}", with: fdMoodPhrase(p))
        }
        return out
    }

    /// L'état d'esprit du joueur, en clair : ce que les scènes de rendez-vous racontent
    /// dépend d'abord de la tête dans laquelle il les aborde.
    private func fdMoodPhrase(_ p: FDPlayer) -> String {
        if p.cond.moral >= 72 && p.cond.confiance >= 68 { return "tu te sens intouchable" }
        if p.cond.moral <= 32 { return "tu traînes une saison qui t'a usé" }
        if p.cond.confiance <= 32 { return "tu doutes de tout depuis des semaines" }
        if p.cond.fatigue >= 70 { return "tu es cuit et tu le sais" }
        return "tu es dans un entre-deux, ni lancé ni perdu"
    }

    private func pickHandwrittenScene(_ p: FDPlayer) -> FDSceneDef? {
        // Les scènes de rendez-vous (grand match de la saison) ont leur propre moment : elles
        // ne doivent jamais tomber au hasard d'une semaine ordinaire.
        let pool = FDScenes.filter { $0.beat == nil && sceneEligible($0, player: p) }
        // With several hundred scenes available, a career should exhaust what it has never
        // seen before showing anything twice — otherwise the same handful keeps coming back.
        let unseen = pool.filter { !usedSceneIds.contains($0.id) }
        let candidates = unseen.isEmpty ? pool : unseen
        // Et parmi celles-là, d'abord celles qu'aucune des dernières carrières n'a servies.
        let fresh = candidates.filter { !recentSceneIds.contains($0.id) }
        guard var picked = (fresh.isEmpty ? candidates : fresh).randomElement() else { return nil }
        rememberScene(picked.id)
        picked.text = personalize(picked.text, player: p)
        picked.character = personalize(picked.character, player: p)
        return picked
    }

    private func genericEvent(_ p: FDPlayer) -> FDCurrentScene {
        let table: [(String, String, [FDEffect])]
        if p.status == .pro && Double.random(in: 0...1) < 0.2 {
            table = FDGenericPress
        } else if Double.random(in: 0...1) < 0.55 {
            table = FDGenericTraining
        } else {
            table = FDGenericLife
        }
        let picked = table.randomElement()!
        let scene = FDSceneDef(
            id: "generic_" + UUID().uuidString, category: "Quotidien", minAge: 0, maxAge: 200,
            location: picked.0, character: "—", text: picked.1,
            choices: [FDChoice(label: "Continuer", effects: picked.2)]
        )
        return .story(scene)
    }

    /// La part de la saison que le joueur a réellement jouée, de 0 à 1. Tout ce qui se juge
    /// sur le temps de jeu passe par là : plus aucun seuil n'est un nombre de matchs en dur,
    /// donc deux carrières qui ont joué « peu » ne le sont plus pour la même raison ni au
    /// même moment.
    func playedShare(_ p: FDPlayer) -> Double {
        let fixtures = p.seasonFixtures ?? 0
        guard fixtures >= 4 else { return 1.0 }
        return min(1.0, Double(p.seasonMatches) / Double(fixtures))
    }

    // MARK: - Fil conducteur du défi Gloire du Passé

    /// L'étape du chemin de la légende que le joueur n'a pas encore vécue, s'il a atteint
    /// l'âge auquel elle a eu lieu. On compare avec `<=` pour qu'une étape ne soit jamais
    /// sautée quand une saison passe vite.
    private func pendingLegendStep(_ p: FDPlayer) -> (FDLegendStep, FDLegendChallenge, String)? {
        guard let id = activeLegendChallengeID,
              let legend = FDLegendChallenges.first(where: { $0.id == id }) else { return nil }
        for step in fdLegendPath(id) where step.age <= p.age {
            let key = "legstep_\(id)_\(step.age)"
            if !usedSceneIds.contains(key) { return (step, legend, key) }
        }
        return nil
    }

    /// Traduit la destination écrite dans le chemin d'une légende en club réel, relatif à
    /// celui du joueur. Sans cela, un transfert de légende n'était qu'un texte : le joueur
    /// lisait qu'il signait ailleurs et restait dans le même vestiaire.
    private func resolveLegendMove(_ keyword: String, player p: FDPlayer) -> (FDClub, Int)? {
        let rep = p.club.reputation
        let others = FDAllClubs.filter { $0.id != p.club.id }
        let pool: [FDClub]
        switch keyword {
        case "sommet":
            pool = others.filter { $0.reputation >= 88 }
        case "grand":
            pool = others.filter { $0.reputation > rep + 6 && $0.reputation <= rep + 26 }
        case "modeste":
            pool = others.filter { $0.reputation < rep - 5 && $0.reputation >= rep - 25 }
        case "inferieur":
            pool = others.filter { $0.division > p.club.division }
        case "etranger":
            pool = others.filter { $0.country != p.club.country && abs($0.reputation - rep) <= 14 }
        case "rival":
            // Le rival, c'est le voisin de niveau dans le même pays : celui qu'on n'est pas
            // censé rejoindre.
            pool = others.filter { $0.country == p.club.country && abs($0.reputation - rep) <= 8 }
        case "retour":
            pool = others.filter { $0.country == p.nationality && $0.reputation <= rep }
        default:
            return nil
        }
        guard let club = pool.randomElement() ?? others.filter({ abs($0.reputation - rep) <= 10 }).randomElement() else { return nil }
        // La prime à la signature suit la valeur marchande, comme pour un transfert ordinaire.
        let fee = max(50_000, marketValue(p) / 3)
        return (club, fee)
    }

    /// Le moment de la légende, monté en scène : ce qu'elle a fait à cet âge-là, et les deux
    /// routes qui s'ouvrent — la sienne, ou la tienne.
    private func legendStepScene(_ step: FDLegendStep, legend: FDLegendChallenge, player p: FDPlayer) -> FDSceneDef {
        FDSceneDef(
            id: "legstep_\(legend.id)_\(step.age)", category: "Héritage", minAge: 0, maxAge: 200,
            location: step.place, character: "\(legend.name) · \(legend.era)",
            text: personalize(step.text, player: p),
            choices: [
                legendChoice(step.followLabel, step.followHint, step.followEffects, step.followMove, player: p),
                legendChoice(step.ownLabel, step.ownHint, step.ownEffects, step.ownMove, player: p),
            ])
    }

    /// Une des deux routes d'un moment de légende. Si elle implique un départ, le club est
    /// résolu maintenant et le choix fera vraiment changer de maillot.
    private func legendChoice(_ label: String, _ hint: String, _ effects: [FDEffect],
                              _ move: String?, player p: FDPlayer) -> FDChoice {
        guard let move = move, let (club, fee) = resolveLegendMove(move, player: p) else {
            return FDChoice(label: label, hint: hint, effects: effects)
        }
        return FDChoice(label: "\(label) — \(club.name)",
                        hint: hint + " Direction \(club.name) — \(club.leagueName), \(club.country)"
                            + fdDivisionGap(from: p.club, to: club) + ".",
                        effects: effects, setClub: club, transferFee: fee)
    }

    /// Les thèmes possibles du grand rendez-vous, et la part de chacun selon où en est la
    /// carrière : un joueur renvoyé en réserve joue sa saison sur un barrage, une star joue
    /// une finale européenne ou un tournoi avec sa sélection.
    /// Toutes les saisons n'ont pas leur grand soir. Un remplaçant dans un club de milieu de
    /// tableau peut traverser une année entière sans qu'il ne se passe rien de spectaculaire ;
    /// une année où le club joue le titre et fait un parcours de coupe en a deux. Tiré une
    /// fois par saison et gardé, pour que la forme d'une saison ne soit jamais la même.
    private func ensureClimaxTarget(_ p: FDPlayer) -> Int {
        if let target = p.seasonClimaxTarget { return target }
        let clubEdge = Double(p.club.reputation) - fdDivisionNorm(p.club.division)
        var chance = 0.38 + playedShare(p) * 0.30
        if p.cond.reputation >= 55 { chance += 0.14 }
        if abs(clubEdge) >= 9 { chance += 0.10 }          // le club joue quelque chose, en haut ou en bas
        if p.status == .reserve { chance -= 0.20 }
        let target: Int
        if Double.random(in: 0...1) > min(0.92, max(0.15, chance)) {
            target = 0
        } else if Double.random(in: 0...1) < 0.10 + max(0, clubEdge) / 260 {
            target = 2
        } else {
            target = 1
        }
        if var pp = player { pp.seasonClimaxTarget = target; player = pp }
        return target
    }

    private func climaxWeights(_ p: FDPlayer) -> [(String, Double)] {
        let rep = p.cond.reputation
        if p.status == .reserve { return [("club", 60), ("derby", 30), ("coupe_petit", 10)] }

        // Le niveau réel du club commande. Un club de division régionale ne dispute pas une
        // finale de Coupe Nationale devant quatre-vingt mille personnes : sa grande soirée à
        // lui, c'est la montée, le derby du coin, ou l'exploit d'un tour de coupe. Et on ne
        // reçoit pas une sélection nationale quand on joue en troisième division.
        var weights: [(String, Double)]
        switch p.club.division {
        case 1:
            weights = [("club", 30), ("coupe", 26), ("derby", 10)]
            if p.club.reputation >= 62 { weights.append(("europe", rep >= 60 ? 28 : 15)) }
            if rep >= 55 { weights.append(("selection", rep >= 72 ? 26 : 12)) }
        case 2:
            weights = [("club", 42), ("coupe", 22), ("derby", 16), ("coupe_petit", 10)]
            if rep >= 70 { weights.append(("selection", 6)) }
        case 3:
            weights = [("club", 50), ("derby", 28), ("coupe_petit", 20), ("coupe", 2)]
        default:
            weights = [("club", 55), ("derby", 30), ("coupe_petit", 15)]
        }
        return weights
    }

    /// Tire une scène de rendez-vous : d'abord le thème, avec les poids de la carrière, puis
    /// une scène de ce thème — jamais vue tant qu'il en reste.
    private func pickBeatScene(_ p: FDPlayer, beat: String, weights: [(String, Double)]) -> FDSceneDef? {
        let pool = FDScenes.filter { $0.beat == beat && sceneEligible($0, player: p) }
        guard !pool.isEmpty else { return nil }
        var candidates: [FDSceneDef] = []
        let available = weights.filter { weight in pool.contains { $0.beatTheme == weight.0 } }
        if !available.isEmpty {
            let total = available.reduce(0.0) { $0 + $1.1 }
            var roll = Double.random(in: 0..<total)
            var theme = available[0].0
            for (name, weight) in available {
                if roll < weight { theme = name; break }
                roll -= weight
            }
            candidates = pool.filter { $0.beatTheme == theme }
        }
        if candidates.isEmpty { candidates = pool }
        let unseen = candidates.filter { !usedSceneIds.contains($0.id) }
        let short = unseen.isEmpty ? candidates : unseen
        // Le grand rendez-vous n'arrive qu'une fois par saison : c'est le texte qu'on
        // reverrait le plus vite d'une carrière à l'autre. Il passe donc par la même mémoire.
        let fresh = short.filter { !recentSceneIds.contains($0.id) }
        guard var picked = (fresh.isEmpty ? short : fresh).randomElement() else { return nil }
        rememberScene(picked.id)
        picked.text = personalize(picked.text, player: p)
        picked.character = personalize(picked.character, player: p)
        return picked
    }

    private func generateNextEvent() -> FDCurrentScene {
        guard let p = player else { return .none }
        if let hw = pickHandwrittenScene(p) {
            usedSceneIds.insert(hw.id)
            // Roughly two seasons before a scene can come back at all.
            sceneCooldown[hw.id] = p.calendar.week + p.calendar.season * 100 + 200
            return .story(hw)
        }
        return genericEvent(p)
    }

    /// Combien de scènes ordinaires une saison mérite, une fois retirés les rendez-vous
    /// qu'elle a déjà servis. Deux pour une saison normale, trois pour un joueur installé,
    /// et chaque grand rendez-vous ou étape de légende déjà tombé en retire une : une saison
    /// pleine de moments forts n'a pas besoin qu'on l'allonge avec des scènes de plus.
    /// Il en reste toujours au moins une, pour qu'aucune saison ne soit muette.
    private func storyEventsTarget(_ p: FDPlayer) -> Int {
        let base: Int
        // Une saison où l'on joue peu, ou une fin de carrière, se raconte en moins de scènes.
        if playedShare(p) < 0.3 && p.calendar.week > p.calendar.seasonWeeks / 2 {
            base = 2
        } else if p.status == .reserve || p.age >= 34 {
            base = 2
        } else if p.cond.reputation >= 55 || p.leagueTitles > 0 {
            // Une saison de joueur installé, suivi et attendu, en mérite une de plus.
            base = 3
        } else {
            base = 2
        }
        return max(1, base - (p.seasonBeats ?? 0))
    }

    /// Un rendez-vous vient de tomber : il compte comme un moment de la saison et allège
    /// d'autant les scènes ordinaires qui restent à venir.
    private func noteSeasonBeat() {
        guard var p = player else { return }
        p.seasonBeats = (p.seasonBeats ?? 0) + 1
        player = p
    }

    /// Le thème du grand rendez-vous en cours, s'il y en a un : le choix résolu déclenchera
    /// alors un vrai match, dont le résultat est raconté au joueur.
    private var bigMatchPending: String?

    // MARK: - Choice resolution

    /// Resolves a choice and, unless nothing changed, shows a dedicated outcome screen with the
    /// effects revealed as pills — the choice buttons themselves never show +/- beforehand.
    func resolveChoice(_ choice: FDChoice, category: String) {
        var pills = applyEffects(choice.effects)
        // Une réponse sans suite écrite laissait l'écran de résultat vide, avec seulement des
        // chiffres : le joueur voyait bouger ses jauges sans jamais savoir ce que son choix
        // avait provoqué. Faute de texte écrit à la main, la conséquence est recomposée à
        // partir de ce qui a réellement changé.
        var narrative = choice.hint.isEmpty
            ? fdConsequence(effects: choice.effects, seed: choice.label.hashValue)
            : choice.hint

        if let chance = choice.riskChance, Double.random(in: 0...1) < chance, let riskEffects = choice.riskEffects, let riskText = choice.riskText {
            pills += applyEffects(riskEffects)
            narrative = riskText
            // The same mechanism covers a gamble that pays off and one that turns sour, so
            // the journal picks its icon from what actually happened.
            let net = riskEffects.reduce(0) { total, e in
                total + (e.cond == "fatigue" ? -e.delta : e.delta) + (e.money ?? 0) / 1000
            }
            pushJournal(riskText, icon: net >= 0 ? "🍀" : "⚠️")
        }
        if let trait = choice.trait, var p = player, !p.traits.contains(trait) {
            p.traits.append(trait)
            player = p
            pushJournal("Trait débloqué : \(trait.rawValue).", icon: "🎭")
        }
        if let weeks = choice.delayedWeeks, let effects = choice.delayedEffects, let text = choice.delayedText, var p = player {
            let due = p.calendar.week + p.calendar.season * 100 + weeks
            p.delayedEffects.append(FDDelayedEffect(dueWeek: due, effects: effects, text: text))
            player = p
        }
        if let status = choice.setStatus, var p = player {
            p.status = status
            player = p
            pushJournal("Nouveau statut : \(status.rawValue)", icon: "📄")
        }
        if let salary = choice.setContractSalary, let years = choice.setContractYears, var p = player {
            p.contract = FDContract(salary: salary, years: years)
            player = p
            pushJournal("Contrat professionnel signé : \(fdFormatMoney(salary))/semaine.", icon: "📄")
        }
        if let style = choice.setPlayStyle, var p = player, p.playStyleLabel == nil {
            p.playStyleLabel = style
            player = p
            pushJournal("Identité de jeu adoptée : \(style).", icon: "🧬")
        }
        if let club = choice.setClub, var p = player, club.id != p.club.id {
            let fee = choice.transferFee ?? 0
            p.transferHistory.append(FDTransferRecord(age: p.age, clubName: club.name, country: club.country,
                                                      division: club.division, fee: fee))
            // La part du joueur sur son propre transfert, comme pour un départ ordinaire.
            let bonus = Int((Double(fee) * 0.05).rounded())
            p.money += bonus
            p.seasonMoneyDelta += bonus
            p.club = club
            player = p
            pushJournal("Transfert signé : \(club.name) (\(club.country)) pour \(fdFormatMoney(fee)).", icon: "✈️")
        }

        // Un grand rendez-vous se joue vraiment : le choix fait, le match a lieu, et le
        // lendemain arrive sous forme d'article — le résultat et ce qu'il change. Pas de
        // note : une finale se raconte, elle ne se chiffre pas.
        if let theme = bigMatchPending {
            bigMatchPending = nil
            let result = simulateMatch(forceStart: true)
            if let me = player {
                narrative = (narrative.isEmpty ? "" : narrative + "\n\n")
                    + fdBigMatchReport(result, theme: theme, player: me)
            }
            if result.goals > 0 {
                pills.append(FDEffectPill(label: result.goals > 1 ? "Buts" : "But",
                                          valueText: "+\(result.goals)", positive: true))
            }
            if result.assists > 0 {
                pills.append(FDEffectPill(label: "Passe déc.", valueText: "+\(result.assists)", positive: true))
            }
            pushJournal(fdBigMatchHeadline(result, theme: theme), icon: result.teamScore > result.oppScore ? "🏆" : "⚽")
        }

        if pills.isEmpty && narrative.isEmpty {
            advanceWeek()
        } else {
            currentScene = .outcome(FDChoiceOutcome(category: category, narrative: narrative, pills: pills))
        }
    }

    /// Called when the player taps "Continuer" on the outcome screen, moving the story forward.
    func continueAfterOutcome() {
        advanceWeek()
    }

    private func checkDelayed() {
        guard var p = player, !p.delayedEffects.isEmpty else { return }
        let nowKey = p.calendar.week + p.calendar.season * 100
        let due = p.delayedEffects.filter { $0.dueWeek <= nowKey }
        if !due.isEmpty {
            p.delayedEffects.removeAll { $0.dueWeek <= nowKey }
            player = p
            for d in due {
                applyEffects(d.effects)
                pushJournal(d.text, icon: "💡")
            }
        }
    }

    private func weeklyTick() {
        guard var p = player else { return }
        p.calendar.week += 1
        let weeklyIncome = Int((Double(p.contract.salary) * 0.82).rounded())
        p.money += weeklyIncome
        p.seasonMoneyDelta += weeklyIncome
        p.cond.fatigue = min(max(p.cond.fatigue - 9, 0), 100)
        p.cond.forme = min(max(p.cond.forme + Int(((58 - Double(p.cond.forme)) * 0.14).rounded()), 0), 100)
        p.cond.confiance = min(max(p.cond.confiance + Int(((55 - Double(p.cond.confiance)) * 0.14).rounded()), 0), 100)
        player = p
        checkDelayed()
    }

    /// La probabilité qu'une carrière s'arrête à la fin de cette saison-là. Elle monte avec
    /// l'âge, mais surtout avec ce que la saison a été : celui qui ne joue plus raccroche à
    /// trente-et-un ans, celui qui tient son rang joue jusqu'à quarante. Rien n'est écrit.
    private func retirementChance(_ p: FDPlayer, share: Double) -> Double {
        guard p.age >= 30 else { return 0 }
        var chance = Double(p.age - 30) * 0.05
        if share < 0.35 { chance += 0.16 }
        if p.status == .reserve { chance += 0.15 }
        if overall(p) < p.club.reputation - 12 { chance += 0.08 }
        if p.cond.fatigue > 75 { chance += 0.06 }
        if p.money > 8_000_000 { chance += 0.04 }
        if p.cond.moral < 35 { chance += 0.05 }
        // Il lui manque encore quelque chose : on ne s'arrête pas les mains vides.
        if p.leagueTitles + p.cupTitles == 0 && p.age < 34 { chance -= 0.06 }
        return min(0.95, max(0, chance))
    }

    /// Le niveau moyen d'un club de cette division : c'est l'étalon auquel on compare le club
    /// du joueur pour savoir s'il joue le haut ou le bas de tableau.
    private func fdDivisionNorm(_ division: Int) -> Double {
        switch division {
        case 1: return 62
        case 2: return 48
        case 3: return 36
        default: return 28
        }
    }

    /// Ce qui arrive au club entre deux saisons. Un club ne reste pas planté dans sa division
    /// toute une carrière : il monte, il descend, et de temps en temps quelque chose lui tombe
    /// dessus — un investisseur, un président ambitieux, ou un dépôt de bilan. Le joueur suit,
    /// et c'est ce qui rend deux carrières au même club différentes.
    private func applyClubFortunes(_ p: inout FDPlayer, position: Int, summary: inout [String]) {
        func note(_ line: String, _ icon: String) {
            summary.append(line)
            p.journal.insert(FDJournalEntry(week: p.calendar.seasonWeeks, season: p.calendar.season,
                                            age: p.age, text: line, icon: icon), at: 0)
        }

        let division = p.club.division
        // Montée : les deux premiers montent, et le barrage laisse une chance aux suivants.
        if division > 1 && (position <= 2 || (position <= 5 && Double.random(in: 0...1) < 0.35)) {
            p.club.division -= 1
            p.club.reputation = min(99, p.club.reputation + Int.random(in: 5...9))
            p.contract.salary = Int(Double(p.contract.salary) * 1.2)
            note("⬆️ \(p.club.name) monte en \(p.club.leagueName) !", "⬆️")
        } else if division < 4 && position >= 18 {
            p.club.division += 1
            p.club.reputation = max(10, p.club.reputation - Int.random(in: 4...8))
            p.contract.salary = max(400, Int(Double(p.contract.salary) * 0.8))
            note("⬇️ \(p.club.name) descend en \(p.club.leagueName).", "⬇️")
        }

        // Et les coups de théâtre, rares mais réels : une carrière doit pouvoir basculer sans
        // que le joueur y soit pour quoi que ce soit.
        let roll = Double.random(in: 0...1)
        if roll < 0.04 {
            let gain = Int.random(in: 8...16)
            p.club.reputation = min(99, p.club.reputation + gain)
            p.rel.president = min(100, p.rel.president + 10)
            p.contract.salary = Int(Double(p.contract.salary) * 1.35)
            note("💰 \(p.club.name) a été racheté. Le nouveau propriétaire annonce des ambitions, et ton salaire suit.", "💰")
        } else if roll < 0.06 {
            p.club.reputation = max(10, p.club.reputation - Int.random(in: 10...16))
            p.contract.salary = max(400, p.contract.salary / 2)
            p.rel.president = max(0, p.rel.president - 20)
            if p.club.division < 4 {
                p.club.division += 1
                note("💥 Dépôt de bilan : \(p.club.name) est rétrogradé administrativement en \(p.club.leagueName). Les salaires sont divisés et le vestiaire se vide.", "💥")
            } else {
                note("💥 \(p.club.name) frôle le dépôt de bilan : salaires divisés, effectif bradé.", "💥")
            }
        } else if roll < 0.09 {
            p.club.reputation = min(99, p.club.reputation + Int.random(in: 3...7))
            p.rel.president = 55
            note("🪑 Nouveau président à \(p.club.name) : tout est à refaire avec lui, et il a de l'ambition.", "🪑")
        } else if roll < 0.11 {
            p.club.academyQuality = min(99, p.club.academyQuality + Int.random(in: 5...12))
            p.club.youthMinutes = min(99, p.club.youthMinutes + Int.random(in: 6...14))
            note("🌱 \(p.club.name) mise tout sur son centre de formation : les jeunes joueront davantage.", "🌱")
        }
    }

    /// Advances week by week, simulating matches silently in the background and stopping the
    /// player on the season's narrative beats. Narrative gets first claim on the season's final
    /// stretch — matches are flexible about exactly which week they land on and can still catch
    /// up earlier, so they yield once both quotas are racing to fit in what's left. Without this,
    /// matches (checked unconditionally first) starved the story quota almost every season.
    func advanceWeek() {
        while true {
            weeklyTick()
            guard let p = player else { return }
            if p.calendar.week >= p.calendar.seasonWeeks {
                endSeason()
                saveGame()
                return
            }

            let weeksLeft = max(1, p.calendar.seasonWeeks - p.calendar.week + 1)

            // Le fil conducteur de la légende poursuivie passe avant tout le reste : ces
            // moments-là sont ceux qui donnent son sens au défi.
            if let (step, legend, key) = pendingLegendStep(p),
               weeksLeft <= 3 || Double.random(in: 0...1) < 0.3 {
                usedSceneIds.insert(key)
                noteSeasonBeat()
                currentScene = .story(legendStepScene(step, legend: legend, player: p))
                saveGame()
                return
            }

            // Le grand rendez-vous : finale, match du titre, maintien, soirée européenne ou
            // sélection. Il tombe dans le dernier quart de saison, à une semaine imprévisible,
            // mais aucune saison ne se termine sans l'avoir joué.
            let climaxTarget = ensureClimaxTarget(p)
            let climaxDone = p.seasonClimaxDone ?? 0
            let climaxLeft = climaxTarget - climaxDone
            // Deux rendez-vous dans la même saison ont besoin de plus de place qu'un seul.
            let window = climaxTarget >= 2 ? p.calendar.seasonWeeks / 2 : max(3, p.calendar.seasonWeeks / 4)
            if climaxLeft > 0,
               weeksLeft <= window,
               weeksLeft <= 2 || Double.random(in: 0...1) < Double(climaxLeft) / Double(weeksLeft),
               let big = pickBeatScene(p, beat: "climax", weights: climaxWeights(p)) {
                if var pp = player { pp.seasonClimaxDone = climaxDone + 1; player = pp }
                usedSceneIds.insert(big.id)
                // Un grand rendez-vous se joue : le choix décidera de la soirée, et le
                // résultat du match sera raconté juste après.
                bigMatchPending = big.beatTheme ?? "club"
                noteSeasonBeat()
                currentScene = .story(big)
                saveGame()
                return
            }

            let storyLeft = storyEventsTarget(p) - p.seasonStoryEvents

            if storyLeft > 0 && (storyLeft >= weeksLeft || Double.random(in: 0...1) < Double(storyLeft) / Double(weeksLeft)) {
                currentScene = generateNextEvent()
                if var pp = player { pp.seasonStoryEvents += 1; player = pp }
                autoResolveExpress()
                saveGame()
                return
            }
            // Pas de quota de matchs : le championnat tourne, une semaine sur huit est une
            // trêve, et c'est la confiance du coach, la forme et le niveau qui décident si le
            // joueur entre ou regarde. Deux carrières ne comptent donc jamais le même nombre
            // de matchs, et celui qui perd sa place le voit dans ses stats.
            if Double.random(in: 0...1) > 0.12 {
                _ = simulateMatch()
                continue
            }
            // Trêve : ni match ni scène, la semaine passe.
        }
    }

    /// Express mode: auto-resolve minor filler events, always stop on matches / written scenes / season summaries.
    private func autoResolveExpress() {
        guard let p0 = player, p0.mode == .express else { return }
        var guardCount = 0
        var skipped = 0
        suppressToast = true
        while guardCount < 5 {
            guard case let .story(scene) = currentScene, scene.id.hasPrefix("generic_"), let choice = scene.choices.first else { break }
            applyEffects(choice.effects)
            guardCount += 1
            skipped += 1
            weeklyTick()
            guard let p = player else { break }
            if p.calendar.week >= p.calendar.seasonWeeks {
                suppressToast = false
                endSeason()
                return
            }
            currentScene = generateNextEvent()
        }
        suppressToast = false
        if skipped > 0 { showToast("⏩ \(skipped) évènement(s) mineur(s) résolu(s) automatiquement") }
    }

    // MARK: - Season end / progression

    private func endSeason() {
        guard var p = player else { return }
        let avgForm = p.seasonForm.isEmpty ? 0 : p.seasonForm.reduce(0, +) / Double(p.seasonForm.count)
        p.history.insert(FDSeasonRecord(season: p.calendar.season, age: p.age, club: p.club.name, status: p.status,
                                          apps: p.seasonMatches, goals: p.seasonGoals, assists: p.seasonAssists,
                                          avgRating: (avgForm * 10).rounded() / 10), at: 0)

        // La part de la saison réellement jouée, retenue avant que les compteurs ne soient
        // remis à zéro : elle sert au bilan, aux trophées et à la vitesse de progression.
        let seasonShare = playedShare(p)

        var summary: [String] = [
            "Saison \(fdSeasonLabel(p.calendar.season)) terminée : \(p.seasonMatches) match(s), \(p.seasonGoals) but(s), \(p.seasonAssists) passe(s) décisive(s).",
            "Note moyenne : \(p.seasonForm.isEmpty ? "—" : String(format: "%.1f", avgForm))/10.",
        ]

        // Le classement est d'abord celui du club, pas du joueur : ce qui compte, c'est ce que
        // vaut le club par rapport au niveau moyen de sa division. Le joueur pèse dessus, sans
        // le décider seul — sinon un bon milieu faisait monter un club amateur en Ligue 1 en
        // quatre saisons, et le championnat n'avait plus aucun sens.
        let clubEdge = Double(p.club.reputation) - fdDivisionNorm(p.club.division)
        let playerEdge = (Double(overall(p)) - Double(p.club.reputation)) / 8
        let leaguePosition = min(20, max(1, Int((11.0 - clubEdge / 3.0 - playerEdge
                                                 + Double.random(in: -4...4)).rounded())))
        p.history[0].leaguePosition = leaguePosition
        summary.append("Classement : \(leaguePosition)e de \(p.club.leagueName).")
        if leaguePosition == 1 {
            p.leagueTitles += 1
            summary.append("🏆 Champion de \(p.club.leagueName) avec \(p.club.name) !")
        }
        // Une coupe nationale ne se gagne pas depuis la division régionale.
        let cupChance = p.club.division <= 2
            ? 0.06 + Double(p.cond.reputation) / 600 - Double(p.club.division - 1) * 0.03
            : 0.004
        if Double.random(in: 0...1) < cupChance {
            p.cupTitles += 1
            summary.append("🏆 Vainqueur de la Coupe Nationale !")
        }

        // Le club vit sa propre vie : il monte, il descend, il se fait racheter, il coule.
        applyClubFortunes(&p, position: leaguePosition, summary: &summary)

        // Objectives set at the previous bilan, evaluated now against this season's real numbers.
        if let obj = p.clubObjective {
            let achieved = evaluateObjective(obj, leaguePosition: leaguePosition, p: p)
            if achieved {
                let prime = max(20_000, marketValue(p) / 200)
                p.money += prime
                p.seasonMoneyDelta += prime
                summary.append("✅ Objectif du club : \(obj.text) (prime +\(fdFormatMoney(prime)))")
            } else {
                summary.append("❌ Objectif du club : \(obj.text)")
            }
        }
        if let obj = p.personalObjective {
            let achieved = evaluateObjective(obj, leaguePosition: leaguePosition, p: p)
            summary.append((achieved ? "✅ Objectif personnel : " : "❌ Objectif personnel : ") + obj.text)
        }

        // Season's net financial line — salary/sponsors plus every narrative money swing, can go negative.
        if p.seasonMoneyDelta >= 0 {
            summary.append("💰 +\(fdFormatMoney(p.seasonMoneyDelta)) (salaire & sponsors)")
        } else {
            summary.append("💸 -\(fdFormatMoney(abs(p.seasonMoneyDelta))) (pertes financières de la saison)")
        }

        let rivalLine = rivalSeasonBlurb(&p)
        if !rivalLine.isEmpty { summary.append(rivalLine) }

        // Individual awards — read from the record just inserted, before season counters reset.
        if (p.status == .pro || p.status == .veteran) && seasonShare >= 0.35 {
            // Aucun palier à franchir : plus la saison est forte, plus la chance monte.
            // Vingt-deux buts ne donnent pas droit à un trophée, ils donnent une chance —
            // et trente en donnent une bien meilleure, sans jamais rien garantir.
            let seasonGoals = p.history[0].goals
            let shoeChance = min(0.9, Double(seasonGoals - 12) / 40.0)
            if Double.random(in: 0...1) < shoeChance {
                p.awardCounts[FDAward.soulierDor.rawValue, default: 0] += 1
                summary.append("🥾 Soulier d'Or de la saison !")
            }
            let ballonChance = min(0.6, (avgForm - 6.9) * 0.30
                                   + Double(p.cond.reputation - 55) / 400
                                   + Double(seasonGoals) / 320
                                   + Double(p.leagueTitles > 0 ? 0.04 : 0))
            if Double.random(in: 0...1) < ballonChance {
                p.awardCounts[FDAward.ballonDor.rawValue, default: 0] += 1
                summary.append("🏆 Ballon d'Or ! Le sommet individuel du football.")
            } else if p.age <= 23, Double.random(in: 0...1) < min(0.32, (avgForm - 6.4) * 0.28) {
                p.awardCounts[FDAward.revelation.rawValue, default: 0] += 1
                summary.append("⭐ Révélation de la saison !")
            }
        }

        // The season's figures, kept before the counters reset, so the chronicle and the
        // report tiles can be written from what actually happened this year.
        let recApps = p.history[0].apps
        let recGoals = p.history[0].goals
        let recAssists = p.history[0].assists
        let recRating = p.history[0].avgRating
        let recClub = p.history[0].club
        let recSeasonLabel = fdSeasonLabel(p.calendar.season)

        p.age += 1
        p.seasonMatches = 0; p.seasonGoals = 0; p.seasonAssists = 0; p.seasonForm = []; p.seasonStoryEvents = 0
        p.seasonFixtures = 0
        // Une nouvelle année, une nouvelle humeur : elle sera tirée au premier match.
        p.seasonMood = nil
        p.seasonClimaxTarget = nil
        p.seasonClimaxDone = 0
        p.seasonBeats = 0
        p.seasonMoneyDelta = 0
        p.calendar.season += 1; p.calendar.week = 0

        // Growth pass — weighted toward the attributes that matter for this position
        let talent = fdTalentTier(p.talentTier)
        // Le palier ne joue pas que sur le plafond : une pépite progresse aussi plus vite,
        // un joueur tardif grappille. C'est ce qui fait qu'une carrière « pète » ou traîne.
        let gf = ageGrowthFactor(p.age) * (ageGrowthFactor(p.age) > 0 ? talent.growthFactor : 1.0)
        let w = p.position.weights

        // Une saison ne fait pas progresser d'un cran fixe : elle fait progresser de ce
        // qu'elle a été. Le temps de jeu pèse le plus lourd, la note du bilan et la
        // confiance du coach ensuite — les choix de l'année se retrouvent donc dans les
        // attributs. Et une part de hasard reste, large, pour que deux carrières menées
        // exactement pareil ne donnent jamais le même joueur.
        let minutesWeight = 0.35 + seasonShare * 0.9
        let ratingPush = recRating > 0 ? (recRating - 6.2) / 6.0 : 0
        let trustPush = (Double(p.rel.coach) - 45) / 320
        // L'aléa de progression est lui aussi au tempérament de la carrière : régulière,
        // elle avance d'un pas égal ; cyclique, elle stagne un an puis prend dix points.
        let volatility = p.careerVolatility ?? 1.0
        let luck = Double.random(in: max(0.35, 1 - 0.34 * volatility)...(1 + 0.40 * volatility))
        let seasonFactor = max(0.2, min(2.1, (minutesWeight + ratingPush + trustPush) * luck))

        for a in FDAttribute.allCases {
            let relevance = 0.55 + w.value(for: a.category) * 1.5
            let cur = p.attr(a)
            let pot = p.potential(a)
            let room = pot - cur
            let delta: Int
            if gf > 0 {
                let step = Double(min(room, Int.random(in: 0...talent.growthStep)))
                delta = Int((step * gf * relevance * seasonFactor).rounded())
            } else {
                delta = Int((Double(Int.random(in: -2...0)) * abs(gf)).rounded())
            }
            p.attrs[a.rawValue] = min(max(cur + delta, 0), pot)
        }

        // Le palier de talent n'est jamais annoncé au lancement : la carrière le révèle
        // elle-même, quand deux saisons ont donné de quoi juger.
        if p.calendar.season == 3 {
            p.journal.insert(FDJournalEntry(week: 0, season: p.calendar.season, age: p.age,
                                            text: talent.reveal, icon: "🔎"), at: 0)
            summary.append("🔎 \(talent.reveal)")
        }

        // La carrière se joue chez les professionnels du premier jour au dernier : il n'y a
        // pas de catégorie de jeunes à traverser. Le seul mouvement possible est la chute —
        // une saison ratée renvoie en réserve — et la remontée qui suit.
        if p.status == .pro || p.status == .veteran {
            let ovr = overall(p)
            let played = seasonShare
            let rated = p.seasonForm.isEmpty ? 6.0 : avgForm
            // Une saison ratée se juge en part de temps de jeu, pas en nombre de matchs :
            // moins d'un tiers des journées jouées, ou une note qui ne tient pas.
            let badSeason = played < 0.3 || rated < 5.3
            let outOfDepth = ovr <= p.club.reputation - 20
            let coachLost = p.rel.coach <= 15
            // Il faut cumuler les signaux : un seul mauvais indicateur ne fait pas descendre.
            if [badSeason, outOfDepth, coachLost].filter({ $0 }).count >= 2 {
                p.status = .reserve
                p.contract = FDContract(salary: max(900, p.contract.salary / 3), years: 1)
                summary.append("⬇️ Rétrogradé en équipe réserve — le club ne compte plus sur toi cette saison.")
            }
        } else if p.status == .reserve {
            let ovr = overall(p)
            let rated = p.seasonForm.isEmpty ? 0 : avgForm
            if ovr >= p.club.reputation - 14 || rated >= 6.4 || p.rel.coach >= 60 {
                p.status = .pro
                p.contract = FDContract(salary: Int.random(in: 3500...10000), years: 2)
                summary.append("⬆️ Rappelé dans le groupe professionnel.")
            } else {
                summary.append("Encore une saison en réserve : la porte du groupe pro ne s'ouvre pas.")
            }
        }
        if p.age >= 35 && p.status == .pro { p.status = .veteran }

        if p.status == .pro || p.status == .veteran {
            p.contract.years = max(0, p.contract.years - 1)
            if p.contract.years <= 0 {
                let factor = 0.78 + Double(overall(p)) / 170
                let newSalary = min(60000, max(400, Int((Double(p.contract.salary) * factor).rounded())))
                p.contract = FDContract(salary: newSalary, years: Int.random(in: 1...3))
                summary.append("Nouveau contrat signé : \(fdFormatMoney(newSalary))/semaine.")
            }
        }

        // National team selection — the stronger the footballing nation, the higher the bar to clear.
        let tier = FDCountryTier[p.nationality] ?? 3
        let selectionThreshold = tier == 1 ? 76 : (tier == 2 ? 66 : 54)
        let wasSelected = p.age <= 34 && overall(p) >= selectionThreshold && Double.random(in: 0...1) < 0.5
        p.inNationalTeam = wasSelected
        if wasSelected {
            p.nationalCaps += Int.random(in: 3...9)
            p.cond.reputation = min(p.cond.reputation + 6, 100)
            summary.append("Sélectionné avec l'équipe nationale \(p.nationality) !")
        }

        // A major international tournament every two seasons, only reachable if selected this season.
        if wasSelected && p.calendar.season % 2 == 0 {
            let tournament = simulateTournament(for: p)
            p.cond.reputation = min(p.cond.reputation + (tournament.champion ? 12 : 4), 100)
            if tournament.champion {
                p.awardCounts["Titre international", default: 0] += 1
            }
            summary.append("\(tournament.competitionName) \(tournament.year) : \(tournament.stageReached).")
            pendingTournament = tournament
        }

        // A late-career transfer, more likely the further the player has outgrown their current club.
        if !(p.age >= 43) && (p.status == .pro || p.status == .veteran) && p.age >= 17 {
            let edgeForTransfer = Double(overall(p)) + Double(p.cond.reputation) / 2 - Double(p.club.reputation)
            let transferChance = min(0.35, max(0.03, 0.06 + edgeForTransfer / 300))
            if Double.random(in: 0...1) < transferChance,
               let target = FDAllClubs.filter({ $0.id != p.club.id && $0.reputation > p.club.reputation && $0.reputation <= overall(p) + 15 }).randomElement() {
                // Un transfert ne se décide plus tout seul dans le bilan : l'offre attend le
                // joueur juste après, et c'est lui qui signe ou qui reste.
                pendingOffer = (club: target, fee: max(50_000, marketValue(p) / 3))
                summary.append("Une offre de \(target.name) (\(target.country)) est arrivée sur le bureau du club.")
            }
        }

        // Aucune carrière ne s'arrête au même endroit. Toutes finissaient à 43 ans, ce qui
        // faisait vingt-sept saisons identiques d'une partie à l'autre. Maintenant, chaque
        // fin de saison passée trente ans pose la question, et la réponse dépend de ce que la
        // carrière est devenue : le temps de jeu, le niveau, le corps, l'argent, l'envie. Et
        // parfois le corps tranche à vingt-six ans sans rien demander à personne.
        if !p.retired {
            var reason: String? = nil
            let injuryRisk = 0.001 + Double(p.cond.fatigue) / 20000 + (p.age >= 32 ? 0.003 : 0)
            if Double.random(in: 0...1) < injuryRisk {
                reason = "blessure"
            } else if Double.random(in: 0...1) < retirementChance(p, share: seasonShare) {
                if p.status == .reserve || seasonShare < 0.3 {
                    reason = "banc"
                } else if leaguePosition == 1 || summary.contains(where: { $0.contains("Vainqueur de la Coupe") }) {
                    reason = "sommet"
                } else {
                    reason = "age"
                }
            } else if p.age >= 42 {
                reason = "age"
            }
            if let reason = reason {
                p.retired = true
                p.retireReason = reason
                let earned = awardLifetimePoints(for: p)
                archiveRetiredCareer(p)
                summary.append(fdRetirementLine(reason: reason, age: p.age, club: p.club.name))
                summary.append("+\(earned) points de carrière (total cumulé : \(lifetimePoints)).")
            }
        }

        // New objectives for the upcoming season, evaluated at the next bilan.
        if p.retired {
            p.clubObjective = nil
            p.personalObjective = nil
        } else {
            p.clubObjective = generateClubObjective(p)
            p.personalObjective = generatePersonalObjective(p)
        }

        player = p

        // Trophies won this season, read from the lines the engine just produced, so the
        // chronicle's tone matches the year.
        let titles = summary.filter { $0.contains("Titre de champion") || $0.contains("Vainqueur de la Coupe") }
        let chronicle = fdSeasonChronicle(player: p, apps: recApps, goals: recGoals, assists: recAssists,
                                          rating: recRating, leaguePosition: leaguePosition, titles: titles)
        let report = FDSeasonReport(
            headline: chronicle.headline, article: chronicle.article,
            apps: recApps, goals: recGoals, assists: recAssists, rating: recRating,
            leaguePosition: leaguePosition, club: recClub, seasonLabel: recSeasonLabel,
            // The two opening lines only restate the tiles and the chronicle, so they go.
            lines: Array(summary.dropFirst(3))
        )

        pushJournal(chronicle.headline, icon: "📰")
        currentScene = .season(report)
        saveGame()
    }

    // MARK: - Season objectives

    private func evaluateObjective(_ obj: FDSeasonObjective, leaguePosition: Int, p: FDPlayer) -> Bool {
        switch obj.kind {
        case "classement": return leaguePosition <= obj.target
        case "buts": return p.seasonGoals >= obj.target
        case "passes": return p.seasonAssists >= obj.target
        case "titulaire": return p.seasonMatches >= obj.target
        case "selection": return p.inNationalTeam
        default: return false
        }
    }

    private func generateClubObjective(_ p: FDPlayer) -> FDSeasonObjective {
        let rep = p.club.reputation
        if rep >= 80 {
            return FDSeasonObjective(text: "Remporter le titre de champion", kind: "classement", target: 1)
        } else if rep >= 60 {
            return FDSeasonObjective(text: "Décrocher une place sur le podium", kind: "classement", target: 3)
        } else if rep >= 35 {
            return FDSeasonObjective(text: "Accrocher le top 6", kind: "classement", target: 6)
        } else {
            return FDSeasonObjective(text: "Assurer le maintien", kind: "classement", target: 16)
        }
    }

    /// L'objectif personnel n'est pas un barème. Il part de ce que le joueur a réellement
    /// produit l'an dernier — ou de ce que son niveau laisse attendre pour une première année —
    /// et on y ajoute une marge tirée au sort. Deux joueurs identiques ne se voient donc
    /// jamais fixer la même barre, et celui qui a explosé est attendu plus haut que celui
    /// qui a subi. Certaines saisons, la barre est basse ; d'autres, elle fait peur.
    private func generatePersonalObjective(_ p: FDPlayer) -> FDSeasonObjective {
        let last = p.history.first
        let margin = Double.random(in: 0.88...1.28)
        let ovr = Double(overall(p))
        switch p.position {
        case .attaquant:
            let expected = max(Double(last?.goals ?? 0), max(4, (ovr - 45) * 0.22))
            let target = max(6, Int((expected * margin).rounded()))
            return FDSeasonObjective(text: "Marquer \(target) buts cette saison", kind: "buts", target: target)
        case .milieu:
            let expected = max(Double(last?.assists ?? 0), max(3, (ovr - 45) * 0.16))
            let target = max(4, Int((expected * margin).rounded()))
            return FDSeasonObjective(text: "Délivrer \(target) passes décisives", kind: "passes", target: target)
        default:
            // Un défenseur, un gardien se jugent sur leur place dans l'équipe : une part des
            // journées, et cette part dépend de l'écart entre son niveau et celui du club.
            let share = min(0.92, max(0.3, 0.55 + (ovr - Double(p.club.reputation)) / 200
                                      + Double.random(in: -0.06...0.09)))
            let target = max(8, Int((share * 34).rounded()))
            return FDSeasonObjective(text: "Disputer \(target) matchs cette saison", kind: "titulaire", target: target)
        }
    }

    // MARK: - Rivalité

    /// A loose parallel career for the player's persistent rival — drifts randomly season to
    /// season and surfaces as a one-line news blurb in the bilan, echoing Destiny Eleven's format.
    private func rivalSeasonBlurb(_ p: inout FDPlayer) -> String {
        guard !p.rivalLastName.isEmpty else { return "" }
        let drift = Int.random(in: -14...16)
        p.rivalMomentum = min(100, max(0, p.rivalMomentum + drift))
        let name = p.rivalLastName
        let pool: [String]
        if p.rivalMomentum >= 75 {
            pool = [
                "Les statistiques de \(name) affolent l'Europe entière cette saison.",
                "\(name) enchaîne les récompenses individuelles, la presse ne parle que de lui.",
                "Saison XXL pour \(name), déjà annoncé favori pour les prochains trophées.",
            ]
        } else if p.rivalMomentum <= 25 {
            pool = [
                "\(name) traverse un passage à vide depuis plusieurs mois, les critiques pleuvent.",
                "Saison compliquée pour \(name), relégué sur le banc de son club.",
                "\(name) traverse une polémique après des propos maladroits en interview.",
            ]
        } else {
            pool = [
                "Rien de marquant du côté de \(name) cette saison, une année sans éclat.",
                "\(name) poursuit sa carrière loin des projecteurs cette saison.",
                "Saison quelconque pour \(name), ni brillante ni catastrophique.",
            ]
        }
        return "📰 " + (pool.randomElement() ?? "")
    }

    private func simulateTournament(for p: FDPlayer) -> FDTournamentSummary {
        let name = ((p.calendar.season / 2) % 2 == 0) ? "Championnat d'Europe" : "Championnat du Monde"
        let year = 2026 + (p.calendar.season - 1)
        let strength = Double(overall(p)) + Double(p.cond.reputation) / 4
        let stages = ["Phase de groupes", "Huitièmes de finale", "Quarts de finale", "Demi-finale", "Finale"]
        var stageIndex = 0
        while stageIndex < stages.count - 1 && Double.random(in: 0...1) < min(0.75, 0.35 + strength / 220) {
            stageIndex += 1
        }
        let champion = stageIndex == stages.count - 1 && Double.random(in: 0...1) < 0.5
        let willPlay = Double.random(in: 0...1) < (0.35 + Double(overall(p)) / 200)
        let minutes = willPlay ? Int.random(in: 60...90) * (stageIndex + 1) / 3 : 0
        let goals = (willPlay && p.position.isAttacker) ? Int.random(in: 0...2) : 0
        let stageLabel = champion ? "Champion !" : (stageIndex == 0 ? "Éliminé dès la phase de groupes" : "Éliminé en \(stages[stageIndex].lowercased())")
        let narrative = willPlay ? "Un vrai rôle dans l'aventure, minutes comprises." : "Du voyage, mais peu de temps de jeu."
        return FDTournamentSummary(competitionName: name, year: year, stageReached: stageLabel, champion: champion, minutesPlayed: minutes, goals: goals, narrative: narrative)
    }

    func continueAfterSeason() {
        guard let p = player, !p.retired else { return }
        if let tournament = pendingTournament {
            pendingTournament = nil
            currentScene = .tournament(tournament)
            saveGame()
            return
        }
        if let mercato = mercatoScene(p) {
            currentScene = .story(mercato)
            saveGame()
            return
        }
        currentScene = generateNextEvent()
        autoResolveExpress()
        saveGame()
    }

    func continueAfterTournament() {
        guard let p = player, !p.retired else { return }
        if let mercato = mercatoScene(p) {
            currentScene = .story(mercato)
            saveGame()
            return
        }
        currentScene = generateNextEvent()
        autoResolveExpress()
        saveGame()
    }

    // MARK: - Intersaison

    /// L'entre-deux-saisons est le moment où une carrière bascule vraiment. Plutôt qu'un
    /// transfert exécuté en silence dans le bilan, le joueur reçoit l'offre, la lit avec sa
    /// nationalité et son état d'esprit du moment, et décide lui-même de partir ou de rester —
    /// les deux ayant leur suite écrite.
    /// Des clubs réellement à la portée du joueur, du plus proche de son niveau au plus
    /// modeste, en privilégiant son pays : c'est là qu'un joueur écarté retrouve du jeu.
    private func mercatoOptions(_ p: FDPlayer, count: Int, band: ClosedRange<Int>) -> [FDClub] {
        let ovr = overall(p)
        let pool = FDAllClubs.filter { club in
            club.id != p.club.id && band.contains(club.reputation - ovr)
        }
        let chezSoi = pool.filter { $0.country == p.nationality }
        let ailleurs = pool.filter { $0.country != p.nationality }
        var picked: [FDClub] = []
        for source in [chezSoi.shuffled(), ailleurs.shuffled()] {
            for club in source where picked.count < count {
                if !picked.contains(where: { $0.id == club.id }) { picked.append(club) }
            }
        }
        return picked
    }

    /// Le salaire que propose un club, à partir de celui d'aujourd'hui et de l'écart de
    /// standing : monter d'un cran paie, descendre coûte.
    private func mercatoSalary(_ p: FDPlayer, at club: FDClub) -> Int {
        let ratio = 1.0 + Double(club.reputation - p.club.reputation) / 40.0
        return max(700, Int((Double(p.contract.salary) * min(max(ratio, 0.35), 2.2)).rounded()))
    }

    private func mercatoChoice(_ p: FDPlayer, club: FDClub, label: String, hint: String,
                               effects: [FDEffect]) -> FDChoice {
        let fee = max(40_000, marketValue(p) / 4)
        let salary = mercatoSalary(p, at: club)
        return FDChoice(label: "\(label) — \(club.name)",
                        hint: hint + " \(club.name) — \(club.leagueName), \(club.country)"
                            + fdDivisionGap(from: p.club, to: club) + ", \(fdFormatMoney(salary)) par semaine.",
                        effects: effects + [FDEffect(money: Int(Double(fee) * 0.05))],
                        setContractSalary: salary, setContractYears: club.reputation > p.club.reputation ? 3 : 2,
                        setClub: club, transferFee: fee)
    }

    /// Le joueur ne joue plus, ou plus assez : trois clubs de son niveau ouvrent leur porte.
    /// C'est la situation qui bloquait — sans elle, une carrière mal partie restait coincée.
    private func mercatoEcarteScene(_ p: FDPlayer) -> FDSceneDef? {
        let options = mercatoOptions(p, count: 3, band: -18...2)
        guard !options.isEmpty else { return nil }
        let text = "Le directeur sportif est clair : tu n'entres plus dans les plans. "
            + "\(p.club.name) ne te retiendra pas, et ton agent a passé l'été à décrocher son téléphone. "
            + "Trois clubs répondent — aucun ne joue le titre, tous te promettent la même chose : tu joues."
        var choices = options.map { club in
            mercatoChoice(p, club: club, label: "Signer", hint: "Tu repars où l'on t'attend vraiment.",
                          effects: [FDEffect(cond: "confiance", delta: 6), FDEffect(cond: "moral", delta: 5),
                                    FDEffect(rel: "coach", delta: 10), FDEffect(cond: "reputation", delta: -3)])
        }
        choices.append(FDChoice(
            label: "Rester et te battre pour ta place",
            hint: "Tu restes malgré tout. Tu t'entraînes seul le matin, tu attends une blessure devant toi, et le club ne t'a rien promis.",
            effects: [FDEffect(attr: .determination, delta: 5), FDEffect(rel: "president", delta: -4),
                      FDEffect(cond: "moral", delta: -5), FDEffect(cond: "reputation", delta: -4)]))
        return FDSceneDef(
            id: "mercato_ecarte_s\(p.calendar.season)", category: "Transfert", minAge: 0, maxAge: 200,
            location: "Bureaux de \(p.club.name)", character: "Le directeur sportif",
            text: text, choices: choices)
    }

    /// Fin de parcours : le club où tout a commencé rappelle, et deux autres à sa portée.
    private func mercatoRetourScene(_ p: FDPlayer) -> FDSceneDef? {
        let origine = FDAllClubs.first { $0.id == p.originClubId && $0.id != p.club.id }
        let autres = mercatoOptions(p, count: origine == nil ? 3 : 2, band: -22...0)
        guard origine != nil || !autres.isEmpty else { return nil }
        var text = "Tu as \(p.age) ans et le club ne compte plus sur toi comme avant. "
        if let origine = origine {
            text += "\(origine.name) a appelé le premier : c'est là que tout a commencé, et ils te veulent pour finir. "
        }
        text += "Deux autres clubs, plus modestes, proposent du temps de jeu. Il reste à décider où s'arrête cette histoire."
        var choices: [FDChoice] = []
        if let origine = origine {
            choices.append(mercatoChoice(p, club: origine, label: "Revenir là où tout a commencé",
                hint: "Tu reviens finir là où on t'a vu débuter. La ville n'a rien oublié, et le salaire non plus.",
                effects: [FDEffect(rel: "fans", delta: 12), FDEffect(cond: "moral", delta: 9),
                          FDEffect(rel: "famille", delta: 6), FDEffect(cond: "reputation", delta: -3)]))
        }
        choices += autres.map { club in
            mercatoChoice(p, club: club, label: "Continuer ailleurs", hint: "Tu repars pour une saison de plus, ailleurs.",
                          effects: [FDEffect(cond: "forme", delta: 4), FDEffect(rel: "coach", delta: 7),
                                    FDEffect(cond: "moral", delta: -3)])
        }
        choices.append(FDChoice(
            label: "Rester ici jusqu'au bout",
            hint: "Tu restes, en jouant de moins en moins. C'est ton club, et c'est ainsi que tu veux que ça se termine.",
            effects: [FDEffect(rel: "president", delta: 6), FDEffect(rel: "fans", delta: 5),
                      FDEffect(cond: "moral", delta: 4), FDEffect(cond: "reputation", delta: -5)]))
        return FDSceneDef(
            id: "mercato_retour_s\(p.calendar.season)", category: "Transfert", minAge: 0, maxAge: 200,
            location: "Intersaison", character: "Ton agent",
            text: text, choices: choices)
    }

    /// Rien d'urgent : le club veut prolonger, et le joueur peut quand même provoquer un
    /// départ s'il le décide — un club de son niveau se présente alors pour de vrai.
    private func mercatoTranquilleScene(_ p: FDPlayer, mood: String) -> FDSceneDef {
        let ailleurs = mercatoOptions(p, count: 1, band: -8...10).first
        let text = "L'été passe sans coup de téléphone spectaculaire : \(p.club.name) veut prolonger, "
            + "et le directeur sportif a préparé les papiers. En entrant dans le bureau, \(mood). "
            + "Rien ne t'oblige à signer aujourd'hui, et rien ne t'oblige à rester non plus."
        var choices: [FDChoice] = [
            FDChoice(label: "Prolonger et t'installer ici",
                     hint: "Tu signes sans discuter. Le club apprécie la fidélité et te le fait savoir, mais personne, dehors, ne retient plus ton nom.",
                     effects: [FDEffect(rel: "president", delta: 8), FDEffect(rel: "fans", delta: 6),
                               FDEffect(cond: "moral", delta: 5), FDEffect(cond: "reputation", delta: -4)],
                     setContractSalary: Int(Double(p.contract.salary) * 1.15), setContractYears: 3),
        ]
        if let club = ailleurs {
            choices.append(mercatoChoice(p, club: club, label: "Demander à partir",
                hint: "Ta demande fuite le soir même, et le club finit par céder. Tu changes de vestiaire à trente jours de la reprise.",
                effects: [FDEffect(rel: "president", delta: -9), FDEffect(rel: "fans", delta: -6),
                          FDEffect(cond: "reputation", delta: 4), FDEffect(rel: "agent", delta: 6)]))
        }
        choices.append(FDChoice(
            label: "Attendre en silence, sans rien signer",
            hint: "Tu reprends l'entraînement sans avoir rien promis. Le vestiaire comprend le message, la direction aussi.",
            effects: [FDEffect(rel: "president", delta: -4), FDEffect(attr: .sangfroid, delta: 3),
                      FDEffect(cond: "moral", delta: -3)]))
        return FDSceneDef(
            id: "mercato_calme_s\(p.calendar.season)", category: "Transfert", minAge: 0, maxAge: 200,
            location: "Bureaux de \(p.club.name)", character: "Le directeur sportif",
            text: text, choices: choices)
    }

    private func mercatoScene(_ p: FDPlayer) -> FDSceneDef? {
        guard p.status == .pro || p.status == .veteran else { return nil }
        let mood = fdMoodPhrase(p)

        guard let offer = pendingOffer else {
            guard p.calendar.season >= 1 else { return nil }
            // Sans offre, l'intersaison ne doit jamais être un cul-de-sac : selon l'état de
            // la carrière, ce sont des clubs à sa portée qui se présentent, ou celui où tout
            // a commencé. Rester est toujours possible — être coincé, non.
            let ovr = overall(p)
            let ecarte = playedShare(p) < 0.45 || p.rel.coach <= 25 || ovr <= p.club.reputation - 12
            let finDeParcours = p.age >= 32 && (ovr < p.club.reputation || playedShare(p) < 0.6)
            if finDeParcours, let scene = mercatoRetourScene(p) { return scene }
            if ecarte, let scene = mercatoEcarteScene(p) { return scene }
            // Quand rien n'est en jeu, l'été ne mérite pas toujours une scène : certaines
            // intersaisons passent sans qu'on en parle, et la saison suivante commence.
            guard Double.random(in: 0...1) < 0.45 else { return nil }
            return mercatoTranquilleScene(p, mood: mood)
        }

        pendingOffer = nil
        let target = offer.club
        let bonus = Int((Double(offer.fee) * 0.05).rounded())
        let expatriation = target.country != p.nationality

        // Écrit en si/sinon plutôt qu'en ternaires imbriqués : le compilateur peine sur les
        // ternaires qui concatènent des chaînes et construisent des tableaux d'effets.
        let intro: String
        if expatriation {
            intro = "\(target.name) veut te faire quitter \(p.nationality). Nouveau pays, nouvelle langue, "
                + "un vestiaire où personne ne t'attend et une famille qui devra suivre ou rester."
        } else {
            intro = "\(target.name) te veut, et c'est encore \(p.nationality) : mêmes routes, mêmes visages. "
                + "Personne n'aurait à déménager très loin."
        }
        // On ne signe pas à l'aveugle : le championnat du club qui appelle, et ce qu'il vaut
        // par rapport au tien, sont dits avant la question.
        let situation = "\(target.name) évolue en \(target.leagueName)"
            + (expatriation ? " (\(target.country))" : "")
            + fdDivisionGap(from: p.club, to: target) + "."
        let text = "\(intro) \(situation) L'offre est sur la table — \(fdFormatMoney(offer.fee)) pour \(p.club.name) — "
            + "et il faut répondre avant la reprise. Au moment de décrocher, \(mood)."

        let signHint: String
        var signEffects: [FDEffect]
        if expatriation {
            signHint = "Tu pars. Les premières semaines sont dures : la langue, les repères, les tiens restés au pays. "
                + "Mais le niveau est au-dessus, et tout le monde le voit."
            signEffects = [FDEffect(cond: "reputation", delta: 8), FDEffect(rel: "fans", delta: -8),
                           FDEffect(rel: "famille", delta: -6), FDEffect(cond: "moral", delta: -4)]
        } else {
            signHint = "Tu signes. Le vestiaire que tu quittes te salue à moitié, celui que tu rejoins t'attend au tournant "
                + "— mais c'est un vrai palier de franchi."
            signEffects = [FDEffect(cond: "reputation", delta: 6), FDEffect(rel: "fans", delta: -6),
                           FDEffect(rel: "vestiaire", delta: -4), FDEffect(cond: "confiance", delta: 4)]
        }
        signEffects.append(FDEffect(money: bonus))

        var choices: [FDChoice] = [
            FDChoice(label: "Signer à \(target.name)", hint: signHint, effects: signEffects,
                     setClub: target, transferFee: offer.fee),
            FDChoice(label: "Rester à \(p.club.name)",
                     hint: "Tu refuses, et le club l'annonce lui-même. Les tribunes t'adoptent pour de bon — mais l'offre ne reviendra pas forcément l'an prochain.",
                     effects: [FDEffect(rel: "fans", delta: 10), FDEffect(rel: "president", delta: 8),
                               FDEffect(rel: "vestiaire", delta: 5), FDEffect(cond: "reputation", delta: -4),
                               FDEffect(rel: "agent", delta: -6)]),
        ]
        if p.cond.reputation >= 40 {
            choices.append(
                FDChoice(label: "Rester, mais exiger un contrat à la hauteur",
                         hint: "Le club cède sur le salaire pour ne pas te perdre. La direction s'en souviendra à la première mauvaise passe.",
                         effects: [FDEffect(rel: "president", delta: -7), FDEffect(rel: "fans", delta: 4),
                                   FDEffect(cond: "confiance", delta: 5)],
                         setContractSalary: Int(Double(p.contract.salary) * 1.6), setContractYears: 3))
        }

        return FDSceneDef(
            id: "mercato_offre_s\(p.calendar.season)", category: "Transfert", minAge: 0, maxAge: 200,
            location: "Intersaison", character: "Ton agent",
            text: text, choices: choices)
    }

    func voluntaryRetire() {
        guard var p = player, !p.retired else { return }
        p.retired = true
        let earned = awardLifetimePoints(for: p)
        archiveRetiredCareer(p)
        player = p
        pushJournal("Retraite anticipée à \(p.age) ans, décision personnelle. +\(earned) points de carrière (total cumulé : \(lifetimePoints)).", icon: "🏁")
        currentScene = .none
        saveGame()
    }
}

func fdFormatMoney(_ v: Int) -> String {
    if v >= 1_000_000 { return String(format: "%.1fM €", Double(v) / 1_000_000) }
    if v >= 1_000 { return "\(Int((Double(v) / 1000).rounded())) k €" }
    return "\(v) €"
}

// MARK: - Wealth scale

/// Money never adds to a career's score: the leaderboard is decided by what was won. The
/// fortune left at retirement is the tie-breaker — banded, so two careers only separate on
/// money when they are otherwise strictly equal.
enum FDWealthScale {
    /// Ordered low-to-high: the threshold a career must reach, and what it is worth.
    static let bands: [(threshold: Int, points: Int)] = [
        (0, 0),
        (500_000, 40),
        (2_000_000, 90),
        (5_000_000, 150),
        (10_000_000, 220),
        (25_000_000, 300),
        (50_000_000, 380),
        (100_000_000, 450),
    ]

    static func points(for money: Int) -> Int {
        var earned = 0
        for band in bands where money >= band.threshold {
            earned = band.points
        }
        return earned
    }

    /// Human-readable rows for the rules screen.
    static var rows: [(label: String, points: Int)] {
        bands.enumerated().map { index, band in
            let next = index + 1 < bands.count ? bands[index + 1].threshold : nil
            let label: String
            if band.threshold == 0 {
                label = "Moins de \(fdFormatMoney(bands[1].threshold))"
            } else if let next {
                label = "\(fdFormatMoney(band.threshold)) – \(fdFormatMoney(next))"
            } else {
                label = "Plus de \(fdFormatMoney(band.threshold))"
            }
            return (label, band.points)
        }
    }
}
