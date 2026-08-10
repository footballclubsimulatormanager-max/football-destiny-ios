import Foundation
import Combine

final class FDGameEngine: ObservableObject {
    @Published var player: FDPlayer?
    @Published var currentScene: FDCurrentScene = .none
    @Published var toast: String? = nil

    /// Persists across careers (survives resetSave): every retirement banks points here,
    /// and new careers get a small starting-potential boost based on the running total.
    @Published var lifetimePoints: Int = UserDefaults.standard.integer(forKey: "footballDestinyLifetimePoints_v1")

    private var usedSceneIds: Set<String> = []
    private var sceneCooldown: [String: Int] = [:]
    private var suppressToast = false
    private var toastDismissWorkItem: DispatchWorkItem?

    private static let storageKey = "footballDestinySave_v1_native"
    private static let lifetimePointsKey = "footballDestinyLifetimePoints_v1"

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

    func startCareer(draft: FDCreationDraft, club: FDClub) {
        // Lifetime points banked from previous retired careers nudge the potential ceiling
        // upward, capped so a long play history helps without breaking the game.
        let metaBonus = min(10, lifetimePoints / 25)
        let potBias = (draft.difficulty == .facile ? 20 : (draft.difficulty == .difficile ? 8 : 14)) + metaBonus
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
            age: 15, status: .u16, club: club,
            attrs: attrs, potential: potential,
            cond: FDCondition(forme: 62, moral: 65, fatigue: 15, confiance: 52, reputation: 4),
            rel: FDRelations(),
            money: startMoney,
            contract: FDContract(salary: 300, years: 0),
            calendar: FDCalendar(season: 1, week: 0, seasonWeeks: 16)
        )
        newPlayer.journal.insert(FDJournalEntry(week: 0, season: 1, age: 15, text: "Début de carrière chez \(club.name) à 15 ans.", icon: "⚽"), at: 0)

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

    private func applyEffects(_ effects: [FDEffect]) {
        guard var p = player else { return }
        var notes: [String] = []
        for e in effects {
            if let attr = e.attr {
                let before = p.attr(attr)
                let cap = p.potential(attr) + 2
                let newVal = min(max(before + e.delta, 0), cap)
                p.attrs[attr.rawValue] = newVal
                if e.delta != 0 { notes.append("\(attr.label) \(e.delta > 0 ? "+" : "")\(e.delta)") }
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
                if e.delta != 0 { notes.append("\(condKey) \(e.delta > 0 ? "+" : "")\(e.delta)") }
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
                if money != 0 { notes.append("\(money > 0 ? "+" : "")\(fdFormatMoney(abs(money)))") }
            }
        }
        player = p
        if !notes.isEmpty { showToast(notes.prefix(3).joined(separator: " · ")) }
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
        let target = matchesTargetThisSeason(p)
        let wantMatch = p.seasonMatches < target && p.calendar.week > 0 && p.calendar.week % max(1, 16 / target) == 0
        if wantMatch {
            return .match(simulateMatch())
        }
        if let hw = pickHandwrittenScene(p) {
            usedSceneIds.insert(hw.id)
            sceneCooldown[hw.id] = p.calendar.week + p.calendar.season * 16 + 10
            return .story(hw)
        }
        return genericEvent(p)
    }

    // MARK: - Choice resolution

    func resolveChoice(_ choice: FDChoice) {
        applyEffects(choice.effects)
        if let chance = choice.riskChance, Double.random(in: 0...1) < chance, let riskEffects = choice.riskEffects, let riskText = choice.riskText {
            applyEffects(riskEffects)
            pushJournal(riskText, icon: "⚠️")
            showToast(riskText)
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

    func advanceWeek() {
        weeklyTick()
        guard let p = player else { return }
        if p.calendar.week >= p.calendar.seasonWeeks {
            endSeason()
        } else {
            currentScene = generateNextEvent()
            autoResolveExpress()
        }
        saveGame()
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

        p.age += 1
        p.seasonMatches = 0; p.seasonGoals = 0; p.seasonAssists = 0; p.seasonForm = []
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

        if p.cond.reputation >= 45 && p.age <= 34 && Double.random(in: 0...1) < 0.22 {
            p.cond.reputation = min(p.cond.reputation + 6, 100)
            summary.append("Convocation avec la sélection nationale A !")
        }

        if p.age >= 43 {
            p.retired = true
            let earned = awardLifetimePoints(for: p)
            summary.append("Fin de carrière officielle. Merci pour cette aventure ! +\(earned) points de carrière (total cumulé : \(lifetimePoints)).")
        }

        player = p
        pushJournal(summary.joined(separator: " "), icon: "🏆")
        currentScene = .season(summary)
        saveGame()
    }

    func continueAfterSeason() {
        guard let p = player, !p.retired else { return }
        currentScene = generateNextEvent()
        autoResolveExpress()
        saveGame()
    }

    func voluntaryRetire() {
        guard var p = player, !p.retired else { return }
        p.retired = true
        let earned = awardLifetimePoints(for: p)
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
