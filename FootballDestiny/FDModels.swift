import Foundation

// MARK: - Static reference data (positions, attributes, enums)

enum FDPosition: String, CaseIterable, Codable, Identifiable, Hashable {
    case gardien = "Gardien"
    case defenseurCentral = "Défenseur central"
    case lateral = "Latéral"
    case milieuDefensif = "Milieu défensif"
    case milieuRelayeur = "Milieu relayeur"
    case milieuOffensif = "Milieu offensif"
    case ailier = "Ailier"
    case avantCentre = "Avant-centre"

    var id: String { rawValue }

    var weights: FDPositionWeights {
        switch self {
        case .gardien:          return FDPositionWeights(tech: 0.15, phys: 0.25, ment: 0.30, def: 0.30)
        case .defenseurCentral: return FDPositionWeights(tech: 0.15, phys: 0.30, ment: 0.20, def: 0.35)
        case .lateral:          return FDPositionWeights(tech: 0.25, phys: 0.30, ment: 0.15, def: 0.30)
        case .milieuDefensif:   return FDPositionWeights(tech: 0.30, phys: 0.20, ment: 0.25, def: 0.25)
        case .milieuRelayeur:   return FDPositionWeights(tech: 0.35, phys: 0.25, ment: 0.30, def: 0.10)
        case .milieuOffensif:   return FDPositionWeights(tech: 0.45, phys: 0.20, ment: 0.30, def: 0.05)
        case .ailier:           return FDPositionWeights(tech: 0.45, phys: 0.35, ment: 0.15, def: 0.05)
        case .avantCentre:      return FDPositionWeights(tech: 0.40, phys: 0.30, ment: 0.25, def: 0.05)
        }
    }

    var isAttacker: Bool {
        [.ailier, .avantCentre, .milieuOffensif].contains(self)
    }
}

struct FDPositionWeights {
    let tech: Double
    let phys: Double
    let ment: Double
    let def: Double

    func value(for category: FDAttrCategory) -> Double {
        switch category {
        case .tech: return tech
        case .phys: return phys
        case .ment: return ment
        case .def: return def
        }
    }
}

enum FDAttrCategory: String, Codable, Hashable {
    case tech, phys, ment, def

    var label: String {
        switch self {
        case .tech: return "Technique"
        case .phys: return "Physique"
        case .ment: return "Mental"
        case .def: return "Défense"
        }
    }
}

enum FDAttribute: String, CaseIterable, Codable, Hashable {
    case control, passe, tir, dribble, centres
    case vitesse, endurance, force, agilite
    case vision, sangfroid, determination, leadership
    case tacle, placement, interception

    var label: String {
        switch self {
        case .control: return "Contrôle"
        case .passe: return "Passe"
        case .tir: return "Tir"
        case .dribble: return "Dribble"
        case .centres: return "Centres"
        case .vitesse: return "Vitesse"
        case .endurance: return "Endurance"
        case .force: return "Force"
        case .agilite: return "Agilité"
        case .vision: return "Vision"
        case .sangfroid: return "Sang-froid"
        case .determination: return "Détermination"
        case .leadership: return "Leadership"
        case .tacle: return "Tacle"
        case .placement: return "Placement"
        case .interception: return "Interception"
        }
    }

    var category: FDAttrCategory {
        switch self {
        case .control, .passe, .tir, .dribble, .centres: return .tech
        case .vitesse, .endurance, .force, .agilite: return .phys
        case .vision, .sangfroid, .determination, .leadership: return .ment
        case .tacle, .placement, .interception: return .def
        }
    }
}

enum FDStatus: String, Codable, CaseIterable, Hashable {
    case u16 = "U16"
    case u18 = "U18"
    case reserve = "Reserve"
    case pro = "Pro"
    case veteran = "Veteran"
}

enum FDMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case narratif = "Narratif"
    case express = "Express"
    var id: String { rawValue }
    var hint: String {
        switch self {
        case .narratif: return "Tu vis chaque évènement."
        case .express: return "Les moments mineurs se résolvent automatiquement, tu ne vois que les décisions et matchs importants."
        }
    }
}

enum FDDifficulty: String, Codable, CaseIterable, Identifiable, Hashable {
    case facile = "Facile", normal = "Normal", difficile = "Difficile"
    var id: String { rawValue }
}

enum FDFoot: String, Codable, CaseIterable, Identifiable, Hashable {
    case droit = "Droit", gauche = "Gauche", ambidextre = "Ambidextre"
    var id: String { rawValue }
}

enum FDBackground: String, Codable, CaseIterable, Identifiable, Hashable {
    case modeste = "Famille modeste"
    case stable = "Famille stable"
    case aisee = "Famille aisée"
    case footballeur = "Famille de footballeur"
    var id: String { rawValue }
}

enum FDPersonality: String, Codable, CaseIterable, Identifiable, Hashable {
    case ambitieux = "Ambitieux", discipline = "Discipliné", charismatique = "Charismatique"
    case reserve = "Réservé", provocateur = "Provocateur", travailleur = "Travailleur"
    case irregulier = "Talentueux mais irrégulier"
    var id: String { rawValue }
}

enum FDStyle: String, Codable, CaseIterable, Identifiable, Hashable {
    case technicien = "Technicien", rapide = "Rapide", puissant = "Puissant"
    case createur = "Créateur", finisseur = "Finisseur", recuperateur = "Récupérateur", leader = "Leader"
    var id: String { rawValue }
}

let FDNations: [String] = ["France","Angleterre","Espagne","Allemagne","Italie","Portugal","Pays-Bas","Belgique","Brésil","Argentine","Uruguay","Colombie","États-Unis","Canada","Mexique","Sénégal","Côte d'Ivoire","Cameroun","Nigeria","Maroc","Algérie","Tunisie","Égypte","Japon","Corée du Sud","Australie","Émirats Arabes Unis","Arabie Saoudite","Turquie","Croatie","Suède","Norvège","Danemark"]

// MARK: - Club

struct FDClub: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var city: String
    var country: String
    var continent: String
    var division: Int
    var reputation: Int
    var academyQuality: Int
    var youthMinutes: Int
}

enum FDClubTier: String, Hashable {
    case elite = "Élite"
    case pro = "Pro"
    case semi = "Semi-pro"
    case amateur = "Amateur"
}

extension FDClub {
    /// A coarse display tier derived from division/reputation, used for the club-picker badge.
    var tier: FDClubTier {
        switch division {
        case 1: return reputation >= 70 ? .elite : .pro
        case 2: return .pro
        case 3: return .semi
        default: return .amateur
        }
    }
}

// MARK: - Player sub-structures

struct FDCondition: Codable {
    var forme: Int
    var moral: Int
    var fatigue: Int
    var confiance: Int
    var reputation: Int
}

struct FDRelations: Codable {
    var coach = 50, staff = 50, directeur = 48, president = 45
    var agent = 0, capitaine = 45, vestiaire = 50, famille = 70
    var partenaire = 0, media = 40, fans = 0
}

struct FDContract: Codable {
    var salary: Int
    var years: Int
}

struct FDCalendar: Codable {
    var season: Int
    var week: Int
    var seasonWeeks: Int
}

struct FDSeasonRecord: Codable, Identifiable {
    var id = UUID()
    var season: Int
    var age: Int
    var club: String
    var status: FDStatus
    var apps: Int
    var goals: Int
    var assists: Int
    var avgRating: Double
    var leaguePosition: Int = 0
}

// MARK: - Traits, awards, transfers, tournaments

/// A personality trait unlocked by a narrative choice, shown in the Distinctions tab
/// and carrying a small, permanent gameplay nudge.
enum FDTrait: String, Codable, CaseIterable, Hashable, Identifiable {
    case leaderNe = "Leader né"
    case joueurEnRetrait = "Joueur en retrait"
    case mercenaire = "Mercenaire"
    case guerrier = "Guerrier"
    case showman = "Showman"
    case talentBrut = "Talent brut"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .leaderNe: return "🧭"
        case .joueurEnRetrait: return "🌫️"
        case .mercenaire: return "💰"
        case .guerrier: return "🛡️"
        case .showman: return "🎤"
        case .talentBrut: return "✨"
        }
    }

    var summary: String {
        switch self {
        case .leaderNe: return "Le vestiaire te suit, un léger bonus de note quand ça compte."
        case .joueurEnRetrait: return "Discret sous pression, mais moins visible des sélectionneurs."
        case .mercenaire: return "Toujours partant pour la meilleure offre, au prix de ta popularité."
        case .guerrier: return "Ne lâche rien, même dans le dur — un supplément de constance."
        case .showman: return "Le public t'adore, ta cote médiatique grimpe plus vite."
        case .talentBrut: return "Des éclairs de génie imprévisibles — de meilleurs pics, mais aussi des soirs sans."
        }
    }
}

/// Individual season/career awards, tracked as counts on the player.
enum FDAward: String, Codable, CaseIterable, Hashable {
    case ballonDor = "Ballon d'Or"
    case soulierDor = "Soulier d'Or"
    case joueurDuChampionnat = "Joueur du championnat"
    case revelation = "Révélation de la saison"
}

/// One entry in the player's transfer path, shown in the Parcours tab.
struct FDTransferRecord: Codable, Identifiable {
    var id = UUID()
    var age: Int
    var clubName: String
    var country: String
    var division: Int
    var fee: Int
}

/// A season-long target, generated ahead of time and evaluated in the following bilan —
/// "kind" drives how it's checked: "classement" against league position, "buts"/"passes"
/// against season totals, "titulaire" against appearances.
struct FDSeasonObjective: Codable {
    var text: String
    var kind: String
    var target: Int
}

/// Result of a biennial international tournament (Coupe du Monde / Championnat d'Europe),
/// shown as its own scene card. Transient like the rest of FDCurrentScene — not persisted.
struct FDTournamentSummary {
    var competitionName: String
    var year: Int
    var stageReached: String
    var champion: Bool
    var minutesPlayed: Int
    var goals: Int
    var narrative: String
}

struct FDJournalEntry: Codable, Identifiable {
    var id = UUID()
    var week: Int
    var season: Int
    var age: Int
    var text: String
    var icon: String
}

struct FDDelayedEffect: Codable {
    var dueWeek: Int
    var effects: [FDEffect]
    var text: String
}

struct FDEffect: Codable {
    var attr: FDAttribute? = nil
    var cond: String? = nil   // "forme" | "moral" | "fatigue" | "confiance" | "reputation"
    var rel: String? = nil    // relation key
    var money: Int? = nil
    var delta: Int = 0
}

// MARK: - Player

struct FDPlayer: Codable {
    var firstName: String
    var lastName: String
    var nationality: String
    var birthCity: String
    var foot: FDFoot
    var position: FDPosition
    var personality: FDPersonality
    var style: FDStyle
    var background: FDBackground
    var difficulty: FDDifficulty
    var mode: FDMode

    var age: Int
    var status: FDStatus
    var club: FDClub

    var attrs: [String: Int]
    var potential: [String: Int]

    var cond: FDCondition
    var rel: FDRelations
    var money: Int
    var contract: FDContract
    var calendar: FDCalendar

    var history: [FDSeasonRecord] = []
    var journal: [FDJournalEntry] = []
    var seasonForm: [Double] = []
    var seasonMatches = 0
    var seasonGoals = 0
    var seasonAssists = 0
    var seasonStoryEvents = 0
    var careerApps = 0
    var careerGoals = 0
    var careerAssists = 0
    var retired = false
    var delayedEffects: [FDDelayedEffect] = []

    var traits: [FDTrait] = []
    var awardCounts: [String: Int] = [:]
    var transferHistory: [FDTransferRecord] = []
    var leagueTitles = 0
    var cupTitles = 0
    var nationalCaps = 0
    var inNationalTeam = false

    /// This season's objectives, generated at the previous season's end and evaluated at the
    /// next — shown as ✅/❌ in the bilan de saison, alongside the club's own target.
    var clubObjective: FDSeasonObjective? = nil
    var personalObjective: FDSeasonObjective? = nil
    /// Net money moved this season (salary, sponsors, narrative wins and losses) — resets every
    /// bilan de saison so the season's financial line reflects only that season.
    var seasonMoneyDelta: Int = 0

    /// A persistent rival, introduced narratively around age 17 and followed loosely across the
    /// whole career via season-recap blurbs and occasional Rivalité scenes.
    var rivalFirstName: String = ""
    var rivalLastName: String = ""
    var rivalMomentum: Int = 50

    /// Locked in once, around age 21, via the Identité de jeu scene — a permanent play-style label.
    var playStyleLabel: String? = nil

    func attr(_ a: FDAttribute) -> Int { attrs[a.rawValue] ?? 0 }
    func potential(_ a: FDAttribute) -> Int { potential[a.rawValue] ?? 0 }

    func relation(_ key: String) -> Int {
        switch key {
        case "coach": return rel.coach
        case "staff": return rel.staff
        case "directeur": return rel.directeur
        case "president": return rel.president
        case "agent": return rel.agent
        case "capitaine": return rel.capitaine
        case "vestiaire": return rel.vestiaire
        case "famille": return rel.famille
        case "partenaire": return rel.partenaire
        case "media": return rel.media
        case "fans": return rel.fans
        default: return 0
        }
    }

    /// Named relations as a lookup, used by the Options screen's overview list.
    var relDict: [String: Int] {
        [
            "Entraîneur": rel.coach, "Staff": rel.staff, "Directeur": rel.directeur, "Président": rel.president,
            "Agent": rel.agent, "Capitaine": rel.capitaine, "Vestiaire": rel.vestiaire, "Famille": rel.famille,
            "Partenaire": rel.partenaire, "Média": rel.media, "Supporters": rel.fans,
        ]
    }

    func condition(_ key: String) -> Int {
        switch key {
        case "forme": return cond.forme
        case "moral": return cond.moral
        case "fatigue": return cond.fatigue
        case "confiance": return cond.confiance
        case "reputation": return cond.reputation
        default: return 0
        }
    }
}

struct FDSaveBlob: Codable {
    var player: FDPlayer
    var usedSceneIds: [String]
    var sceneCooldown: [String: Int]
}

// MARK: - Match result (transient, not persisted)

struct FDMatchResult {
    var started: Bool
    var minutes: Int
    var rating: Double
    var goals: Int
    var assists: Int
    var yellow: Bool
    var red: Bool
    var injury: Bool
    var teamScore: Int
    var oppScore: Int
    var opponentLevel: Int
}

// MARK: - Scene content (transient, not persisted — may hold closures)

struct FDChoice {
    var label: String
    var hint: String = ""
    /// A short display-only badge (e.g. "CLASH", "PROVOCATION", "CARBURANT") shown before the
    /// choice label — purely flavor, unlike `trait` which permanently unlocks an FDTrait.
    var tag: String? = nil
    var effects: [FDEffect] = []
    var riskChance: Double? = nil
    var riskEffects: [FDEffect]? = nil
    var riskText: String? = nil
    var delayedWeeks: Int? = nil
    var delayedEffects: [FDEffect]? = nil
    var delayedText: String? = nil
    var setStatus: FDStatus? = nil
    var setContractSalary: Int? = nil
    var setContractYears: Int? = nil
    var trait: FDTrait? = nil
    /// Set once, by the Identité de jeu scene, to permanently label the player's play style.
    var setPlayStyle: String? = nil
}

struct FDSceneDef {
    var id: String
    var category: String
    var minAge: Int
    var maxAge: Int
    var statuses: [FDStatus]? = nil
    var once: Bool = false
    var location: String
    var character: String
    var text: String
    var choices: [FDChoice]
    var condition: ((FDPlayer) -> Bool)? = nil
    /// Restricts a scene to specific positions — nil means every position is eligible.
    var positions: [FDPosition]? = nil
}

enum FDCurrentScene {
    case none
    case story(FDSceneDef)
    case match(FDMatchResult)
    case season([String])
    case tournament(FDTournamentSummary)
    case outcome(FDChoiceOutcome)
}

/// The result of a choice, revealed only AFTER the player picks — never shown on the choice
/// buttons themselves, so nothing is spoiled before deciding (Destiny Eleven-style reveal).
struct FDEffectPill: Identifiable {
    let id = UUID()
    var label: String
    var valueText: String
    var positive: Bool
}

struct FDChoiceOutcome {
    var category: String
    var narrative: String
    var pills: [FDEffectPill]
}

// MARK: - Creation draft (transient, used during onboarding)

struct FDCreationDraft {
    var firstName = ""
    var lastName = ""
    var nationality = FDNations[0]
    var birthCity = ""
    var foot = FDFoot.droit
    var position = FDPosition.milieuDefensif
    var personality = FDPersonality.ambitieux
    var style = FDStyle.technicien
    var background = FDBackground.stable
    var difficulty = FDDifficulty.normal
    var mode = FDMode.narratif
    var potentialStars = 0
    var club: FDClub? = nil
}

/// Lifetime points earned from past careers can be spent, at creation, on "potential stars"
/// that raise the ceiling of the new player — a crack always starts modest, but experience
/// (i.e. points banked from previous careers) lets you start stronger and faster.
enum FDPotentialShop {
    static let maxStars = 5

    /// Cost of buying the n-th star (1-indexed) — each one costs a little more than the last.
    static func costOfStar(_ n: Int) -> Int { 15 * n }

    /// Total points spent to own this many stars.
    static func cumulativeCost(for stars: Int) -> Int {
        guard stars > 0 else { return 0 }
        return (1...stars).reduce(0) { $0 + costOfStar($1) }
    }

    /// The most stars a given point balance can afford, capped at maxStars.
    static func maxAffordableStars(points: Int) -> Int {
        var stars = 0
        while stars < maxStars && cumulativeCost(for: stars + 1) <= points { stars += 1 }
        return stars
    }
}
