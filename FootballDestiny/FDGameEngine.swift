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
    @Published var ownedCompetenceIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "footballDestinyOwnedCompetences_v1") ?? [])
    @Published var unlockedLegendIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "footballDestinyUnlockedLegends_v1") ?? [])
    @Published var conqueredLegendIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "footballDestinyConqueredLegends_v1") ?? [])
    @Published var archivedCareers: [FDPlayer] = []

    private var activeLegendChallengeID: String?
    private var usedSceneIds: Set<String> = []
    private var sceneCooldown: [String: Int] = [:]
    private var suppressToast = false
    private var toastDismissWorkItem: DispatchWorkItem?
    private var pendingTournament: FDTournamentSummary?

    private static let storageKey = "footballDestinySave_v1_native"
    private static let lifetimePointsKey = "footballDestinyLifetimePoints_v1"
    private static let legendCoinsKey = "footballDestinyLegendCoins_v1"
    private static let ownedCompetencesKey = "footballDestinyOwnedCompetences_v1"
    private static let unlockedLegendsKey = "footballDestinyUnlockedLegends_v1"
    private static let conqueredLegendsKey = "footballDestinyConqueredLegends_v1"
    private static let archiveKey = "footballDestinyArchive_v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.archiveKey),
           let decoded = try? JSONDecoder().decode([FDPlayer].self, from: data) {
            archivedCareers = decoded
        }
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

    func exportSave() -> String? {
        guard let player = player else { return nil }
        let blob = FDSaveBlob(player: player, usedSceneIds: Array(usedSceneIds), sceneCooldown: sceneCooldown)
        guard let data = try? JSONEncoder().encode(blob) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importSave(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8),
              let blob = try? JSONDecoder().decode(FDSaveBlob.self, from: data) else { return false }
        player = blob.player
        usedSceneIds = Set(blob.usedSceneIds)
        sceneCooldown = blob.sceneCooldown
        if let p = player, !p.retired {
            currentScene = generateNextEvent()
            autoResolveExpress()
        }
        saveGame()
        return true
    }

    // MARK: - Career creation

    func startCareer(draft: FDCreationDraft, club: FDClub, legendChallengeID: String? = nil) {
        activeLegendChallengeID = legendChallengeID
        // A crack always starts modest — the ceiling only rises with "potential stars" bought
        // from points banked by previous careers, plus a small automatic bonus for experience.
        let starsBought = min(draft.potentialStars, FDPotentialShop.maxStars)
        let starCost = FDPotentialShop.cumulativeCost(for: starsBought)
        if starCost > 0 {
            lifetimePoints = max(0, lifetimePoints - starCost)
            UserDefaults.standard.set(lifetimePoints, forKey: Self.lifetimePointsKey)
        }
        let metaBonus = min(10, lifetimePoints / 25)

        // Permanent Boutique competences apply to every future career once bought.
        var competencePotential = 0, competenceMoney = 0, competenceReputation = 0
        var competenceForme = 0, competenceConfiance = 0, competenceMoral = 0
        for id in ownedCompetenceIDs {
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

        let potBias = 14 + starsBought * 4 + metaBonus + competencePotential
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
        var potential: [String: Int] = [:]
        for a in FDAttribute.allCases {
            let base = attrs[a.rawValue] ?? 22
            let spread = Int.random(in: (potBias - 8)...(potBias + 18)) + Int((Double(talentSeed) * 0.8).rounded())
            potential[a.rawValue] = min(max(base + spread, base + 6), 90)
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
            calendar: FDCalendar(season: 1, week: 0, seasonWeeks: 16)
        )
        newPlayer.journal.insert(FDJournalEntry(week: 0, season: 1, age: 16, text: "Débuts professionnels chez \(club.name) à 16 ans.", icon: "⚽"), at: 0)

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
        let earned = max(
            5,
            p.careerGoals * 2 + p.careerAssists + p.careerApps / 3
                + p.cond.reputation / 5 + max(0, p.calendar.season - 1) * 3
        )
        lifetimePoints += earned
        UserDefaults.standard.set(lifetimePoints, forKey: Self.lifetimePointsKey)
        return earned
    }

    /// 0-10 "pièces" — deliberately scarce, only a near-perfect career (Ballon d'Or, an
    /// international title, a Soulier d'Or, silverware) gets close to the maximum.
    private func careerQualityCoins(for p: FDPlayer) -> Int {
        var score = 0
        if (p.awardCounts[FDAward.ballonDor.rawValue] ?? 0) > 0 { score += 3 }
        if (p.awardCounts[FDAward.soulierDor.rawValue] ?? 0) > 0 { score += 2 }
        if (p.awardCounts["Titre international"] ?? 0) > 0 { score += 2 }
        if p.leagueTitles > 0 { score += 1 }
        if p.cupTitles > 0 { score += 1 }
        if p.careerGoals >= 150 { score += 1 }
        if p.cond.reputation >= 70 { score += 1 }
        return min(10, score)
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

    @discardableResult
    func purchaseCompetence(_ id: String) -> Bool {
        guard let competence = FDCompetences.first(where: { $0.id == id }), !ownedCompetenceIDs.contains(id), legendCoins >= competence.cost else { return false }
        legendCoins -= competence.cost
        ownedCompetenceIDs.insert(id)
        UserDefaults.standard.set(legendCoins, forKey: Self.legendCoinsKey)
        UserDefaults.standard.set(Array(ownedCompetenceIDs), forKey: Self.ownedCompetencesKey)
        return true
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
                if money != 0 {
                    pills.append(FDEffectPill(label: "Argent", valueText: "\(money > 0 ? "+" : "-")\(fdFormatMoney(abs(money)))", positive: money > 0))
                }
            }
        }
        player = p
        return pills
    }

    // MARK: - Match simulation

    private func opponentLevel(_ p: FDPlayer) -> Int {
        let ovr = Double(overall(p))
        let base = Double(p.club.reputation) * 0.3 + ovr * 0.7 + (p.club.division == 1 ? 3 : 0)
        let jitter = Double(Int.random(in: -14...14))
        return min(max(Int((base + jitter).rounded()), 15), 95)
    }

    private func willStart(_ p: FDPlayer) -> Bool {
        let ovr = Double(overall(p))
        let trust = Double(p.rel.coach + p.rel.president) / 2
        let clubStandard = Double(p.club.reputation)
        var chance = 0.15 + (ovr - clubStandard) / 140 + trust / 300 + (p.status == .pro ? 0.25 : 0) + Double(p.club.youthMinutes) / 400
        chance = min(max(chance * 100, 3), 92) / 100
        return Double.random(in: 0...1) < chance
    }

    private func simulateMatch() -> FDMatchResult {
        guard var p = player else {
            return FDMatchResult(started: false, minutes: 0, rating: 0, goals: 0, assists: 0, yellow: false, red: false, injury: false, teamScore: 0, oppScore: 0, opponentLevel: 0)
        }
        let ovr = Double(overall(p))
        let opp = opponentLevel(p)
        let started = willStart(p)
        let minutes = started ? Int.random(in: 60...90) : (Double.random(in: 0...1) < 0.55 ? Int.random(in: 5...30) : 0)

        var rating = 5.7 + (ovr - Double(opp)) / 18 + (Double(p.cond.forme) - 50) / 60 + (Double(p.cond.confiance) - 50) / 90 + Double(Int.random(in: -9...9)) / 10
        rating += traitRatingModifier(p)
        rating = minutes > 0 ? min(max(rating, 3.0), 10.0) : 0

        let isAttacker = p.position.isAttacker
        var goals = 0, assists = 0
        if minutes > 0 {
            let scoreChance = isAttacker ? (rating - 5.5) * 0.11 + Double(p.attr(.tir)) / 700 : (rating - 7) * 0.03
            if Double.random(in: 0...1) < max(0, scoreChance) { goals = 1 + (Double.random(in: 0...1) < 0.15 ? 1 : 0) }
            let assistChance = (rating - 5.8) * 0.09 + Double(p.attr(.passe)) / 650
            if Double.random(in: 0...1) < max(0, assistChance) { assists = 1 }
        }
        let yellow = minutes > 0 && Double.random(in: 0...1) < (0.06 + Double(p.attr(.force)) / 900)
        let red = yellow && Double.random(in: 0...1) < 0.05
        var injury = false
        if minutes > 0 && Double.random(in: 0...1) < (0.02 + Double(p.cond.fatigue) / 1400) { injury = true }

        let teamScore = min(max(Int.random(in: 0...3) + (ovr > Double(opp) ? 1 : 0) - (ovr < Double(opp) - 15 ? 1 : 0), 0), 6)
        let oppScore = min(max(Int.random(in: 0...3) - (ovr > Double(opp) + 10 ? 1 : 0) + (ovr < Double(opp) - 10 ? 1 : 0), 0), 6)

        if minutes > 0 {
            p.cond.fatigue = min(max(p.cond.fatigue + Int((Double(minutes) / 7).rounded()), 0), 100)
            p.cond.forme = min(max(p.cond.forme + Int(((rating - 6) * 1.0).rounded()), 0), 100)
            p.cond.confiance = min(max(p.cond.confiance + Int(((rating - 6) * 1.2).rounded()), 0), 100)
            p.rel.coach = min(max(p.rel.coach + (rating >= 7 ? 2 : (rating < 5 ? -2 : 0)), 0), 100)
            let repGain = (rating >= 7.5 ? 2 : (rating >= 6.5 ? 1 : 0)) + goals * 2 + assists
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
        let key = p.calendar.week + p.calendar.season * 16
        if let cooldown = sceneCooldown[s.id], cooldown > key { return false }
        if p.age < s.minAge || p.age > s.maxAge { return false }
        if let statuses = s.statuses, !statuses.contains(p.status) { return false }
        if let positions = s.positions, !positions.contains(p.position) { return false }
        if let cond = s.condition, !cond(p) { return false }
        return true
    }

    private func pickHandwrittenScene(_ p: FDPlayer) -> FDSceneDef? {
        let pool = FDScenes.filter { sceneEligible($0, player: p) }
        return pool.randomElement()
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

    private func matchesTargetThisSeason(_ p: FDPlayer) -> Int {
        switch p.status {
        case .u16: return 5
        case .u18: return 8
        case .reserve: return 10
        case .pro, .veteran: return 12
        }
    }

    private func generateNextEvent() -> FDCurrentScene {
        guard let p = player else { return .none }
        if let hw = pickHandwrittenScene(p) {
            usedSceneIds.insert(hw.id)
            sceneCooldown[hw.id] = p.calendar.week + p.calendar.season * 16 + 10
            return .story(hw)
        }
        return genericEvent(p)
    }

    /// A season only surfaces a handful of narrative choices — the rest of the weeks pass
    /// quietly in the background (matches are simulated silently, folded into the season recap).
    private let targetStoryEventsPerSeason = 5

    private func shouldFireStoryEvent(_ p: FDPlayer) -> Bool {
        let remainingQuota = targetStoryEventsPerSeason - p.seasonStoryEvents
        guard remainingQuota > 0 else { return false }
        let weeksLeft = max(1, p.calendar.seasonWeeks - p.calendar.week + 1)
        if remainingQuota >= weeksLeft { return true }
        return Double.random(in: 0...1) < Double(remainingQuota) / Double(weeksLeft)
    }

    // MARK: - Choice resolution

    /// Resolves a choice and, unless nothing changed, shows a dedicated outcome screen with the
    /// effects revealed as pills — the choice buttons themselves never show +/- beforehand.
    func resolveChoice(_ choice: FDChoice, category: String) {
        var pills = applyEffects(choice.effects)
        var narrative = choice.hint

        if let chance = choice.riskChance, Double.random(in: 0...1) < chance, let riskEffects = choice.riskEffects, let riskText = choice.riskText {
            pills += applyEffects(riskEffects)
            narrative = riskText
            pushJournal(riskText, icon: "⚠️")
        }
        if let trait = choice.trait, var p = player, !p.traits.contains(trait) {
            p.traits.append(trait)
            player = p
            pushJournal("Trait débloqué : \(trait.icon) \(trait.rawValue).", icon: "🎭")
        }
        if let weeks = choice.delayedWeeks, let effects = choice.delayedEffects, let text = choice.delayedText, var p = player {
            let due = p.calendar.week + p.calendar.season * 16 + weeks
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
        let nowKey = p.calendar.week + p.calendar.season * 16
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
        p.money += Int((Double(p.contract.salary) * 0.82).rounded())
        p.cond.fatigue = min(max(p.cond.fatigue - 4, 0), 100)
        p.cond.forme = min(max(p.cond.forme + Int(((58 - Double(p.cond.forme)) * 0.14).rounded()), 0), 100)
        p.cond.confiance = min(max(p.cond.confiance + Int(((55 - Double(p.cond.confiance)) * 0.14).rounded()), 0), 100)
        player = p
        checkDelayed()
    }

    /// Advances week by week, simulating matches silently in the background and only stopping
    /// the player on the handful of narrative choices a season actually surfaces.
    func advanceWeek() {
        while true {
            weeklyTick()
            guard let p = player else { return }
            if p.calendar.week >= p.calendar.seasonWeeks {
                endSeason()
                saveGame()
                return
            }

            let target = matchesTargetThisSeason(p)
            let matchWeeksLeft = target - p.seasonMatches
            let weeksLeft = max(1, p.calendar.seasonWeeks - p.calendar.week + 1)
            if matchWeeksLeft > 0 {
                let mustPlayNow = matchWeeksLeft >= weeksLeft
                if mustPlayNow || Double.random(in: 0...1) < Double(matchWeeksLeft) / Double(weeksLeft) {
                    _ = simulateMatch()
                    continue
                }
            }

            if shouldFireStoryEvent(p) {
                currentScene = generateNextEvent()
                if var pp = player { pp.seasonStoryEvents += 1; player = pp }
                autoResolveExpress()
                saveGame()
                return
            }
            // Quiet week: nothing notable happens, keep advancing.
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

        var summary: [String] = [
            "Saison \(p.calendar.season) terminée : \(p.seasonMatches) match(s), \(p.seasonGoals) but(s), \(p.seasonAssists) passe(s) décisive(s).",
            "Note moyenne : \(p.seasonForm.isEmpty ? "—" : String(format: "%.1f", avgForm))/10.",
        ]

        // League position — a rough procedural result tied to how the player's level compares to the club's.
        let edge = Double(overall(p)) - Double(p.club.reputation)
        let leaguePosition = min(20, max(1, Int((11.0 - edge / 5.0 + Double.random(in: -4...4)).rounded())))
        p.history[0].leaguePosition = leaguePosition
        summary.append("Classement : \(leaguePosition)e du championnat.")
        if leaguePosition == 1 {
            p.leagueTitles += 1
            summary.append("🏆 Titre de champion avec \(p.club.name) !")
        }
        if Double.random(in: 0...1) < 0.06 + Double(p.cond.reputation) / 600 {
            p.cupTitles += 1
            summary.append("🏆 Vainqueur de la Coupe Nationale !")
        }

        // Individual awards — read from the record just inserted, before season counters reset.
        if (p.status == .pro || p.status == .veteran) && p.seasonMatches >= 10 {
            let seasonGoals = p.history[0].goals
            if seasonGoals >= 18 && Double.random(in: 0...1) < 0.22 {
                p.awardCounts[FDAward.soulierDor.rawValue, default: 0] += 1
                summary.append("🥾 Soulier d'Or de la saison !")
            }
            if avgForm >= 7.4 && p.cond.reputation >= 55 && Double.random(in: 0...1) < 0.10 {
                p.awardCounts[FDAward.ballonDor.rawValue, default: 0] += 1
                summary.append("🏆 Ballon d'Or ! Le sommet individuel du football.")
            } else if avgForm >= 6.8 && p.age <= 23 && Double.random(in: 0...1) < 0.15 {
                p.awardCounts[FDAward.revelation.rawValue, default: 0] += 1
                summary.append("⭐ Révélation de la saison !")
            }
        }

        p.age += 1
        p.seasonMatches = 0; p.seasonGoals = 0; p.seasonAssists = 0; p.seasonForm = []; p.seasonStoryEvents = 0
        p.calendar.season += 1; p.calendar.week = 0

        // Growth pass — weighted toward the attributes that matter for this position
        let gf = ageGrowthFactor(p.age)
        let w = p.position.weights
        for a in FDAttribute.allCases {
            let relevance = 0.55 + w.value(for: a.category) * 1.5
            let cur = p.attr(a)
            let pot = p.potential(a)
            let room = pot - cur
            let delta: Int
            if gf > 0 {
                delta = Int((Double(min(room, Int.random(in: 0...3))) * gf * relevance).rounded())
            } else {
                delta = Int((Double(Int.random(in: -2...0)) * abs(gf)).rounded())
            }
            p.attrs[a.rawValue] = min(max(cur + delta, 0), pot)
        }

        // Status progression — youth capped at 2 seasons (U16 then U18), then a definitive pro pathway
        if p.status == .u16 {
            p.status = .u18
            summary.append("Promotion en catégorie U18.")
        } else if p.status == .u18 {
            let ovr = overall(p)
            if ovr >= p.club.reputation - 12 || p.cond.reputation >= 16 {
                p.status = .pro
                p.contract = FDContract(salary: Int.random(in: 3000...9000), years: 2)
                summary.append("Promotion directe en équipe professionnelle !")
            } else {
                p.status = .reserve
                p.contract = FDContract(salary: Int.random(in: 800...2000), years: 1)
                summary.append("Intégration à l'équipe réserve pour franchir un dernier palier.")
            }
        } else if p.status == .reserve {
            p.status = .pro
            p.contract = FDContract(salary: Int.random(in: 3500...10000), years: 2)
            summary.append("Appelé en équipe professionnelle !")
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
                let fee = max(50_000, marketValue(p) / 3)
                p.transferHistory.append(FDTransferRecord(age: p.age, clubName: target.name, country: target.country, division: target.division, fee: fee))
                p.money += Int((Double(fee) * 0.05).rounded())
                summary.append("Transfert : \(target.name) (\(target.country)) recrute pour \(fdFormatMoney(fee)).")
                p.club = target
            }
        }

        if p.age >= 43 {
            p.retired = true
            let earned = awardLifetimePoints(for: p)
            archiveRetiredCareer(p)
            summary.append("Fin de carrière officielle. Merci pour cette aventure ! +\(earned) points de carrière (total cumulé : \(lifetimePoints)).")
        }

        player = p
        pushJournal(summary.joined(separator: " "), icon: "🏆")
        currentScene = .season(summary)
        saveGame()
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
        currentScene = generateNextEvent()
        autoResolveExpress()
        saveGame()
    }

    func continueAfterTournament() {
        guard let p = player, !p.retired else { return }
        currentScene = generateNextEvent()
        autoResolveExpress()
        saveGame()
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
