import Foundation

// MARK: - Static reference data (positions, attributes, enums)

enum FDPosition: String, CaseIterable, Codable, Identifiable, Hashable {
    case gardien = "Gardien"
    case defenseur = "Défenseur"
    case milieu = "Milieu"
    case attaquant = "Attaquant"

    var id: String { rawValue }

    var weights: FDPositionWeights {
        switch self {
        case .gardien:   return FDPositionWeights(tech: 0.15, phys: 0.25, ment: 0.30, def: 0.30)
        case .defenseur: return FDPositionWeights(tech: 0.20, phys: 0.30, ment: 0.18, def: 0.32)
        case .milieu:    return FDPositionWeights(tech: 0.37, phys: 0.22, ment: 0.28, def: 0.13)
        case .attaquant: return FDPositionWeights(tech: 0.43, phys: 0.32, ment: 0.20, def: 0.05)
        }
    }

    var isAttacker: Bool {
        self == .attaquant
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
    var hint: String {
        switch self {
        case .facile: return "Une expérience plus clémente, pour découvrir l'histoire sans trop de pression."
        case .normal: return "L'équilibre classique entre défis et progression."
        case .difficile: return "Chaque décision compte double — la moindre erreur se paie cher."
        }
    }
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

    /// The competition name shown to the player. France is modelled down to four tiers and
    /// names them properly; other countries carry fewer divisions and get a generic label.
    var leagueName: String {
        if country == "France" {
            switch division {
            case 1: return "Ligue 1"
            case 2: return "Ligue 2"
            case 3: return "Ligue 3"
            default: return "Régional 1"
            }
        }
        switch division {
        case 1: return "1re division"
        case 2: return "2e division"
        case 3: return "3e division"
        default: return "Division régionale"
        }
    }
}

/// Ce que vaut le championnat d'un club par rapport à celui d'un autre, dit en clair. On ne
/// signe pas à l'aveugle : « une division au-dessus » ou « deux en dessous » change tout à une
/// offre, et le nom d'un club étranger ne dit rien de son niveau.
func fdDivisionGap(from: FDClub, to: FDClub) -> String {
    let gap = from.division - to.division
    switch gap {
    case 0: return from.country == to.country ? "" : ", le même niveau que chez toi"
    case 1: return ", une division au-dessus de la tienne"
    case 2...: return ", \(gap) divisions au-dessus de la tienne"
    case -1: return ", une division en dessous"
    default: return ", \(-gap) divisions en dessous"
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

// MARK: - Shared display helpers

/// The real-world season a career's season 1 maps onto. Seasons are shown as "2026-2027"
/// everywhere rather than as a bare index, so a career reads like a real football timeline.
let FDFirstSeasonYear = 2026

/// "2026-2027" for season 1, "2027-2028" for season 2, and so on.
func fdSeasonLabel(_ season: Int) -> String {
    let start = FDFirstSeasonYear + max(0, season - 1)
    return "\(start)-\(start + 1)"
}

/// Short form used where space is tight, e.g. "26/27".
func fdSeasonLabelShort(_ season: Int) -> String {
    let start = FDFirstSeasonYear + max(0, season - 1)
    return String(format: "%02d/%02d", start % 100, (start + 1) % 100)
}

/// Flag emoji for a country name. Used everywhere a country is displayed — the club picker,
/// the player header, the historique and the leaderboard — so a nationality always reads
/// the same way across the app.
func fdFlag(for nation: String) -> String {
    let flags: [String: String] = [
        "France": "🇫🇷", "Angleterre": "🇬🇧", "Espagne": "🇪🇸", "Allemagne": "🇩🇪",
        "Italie": "🇮🇹", "Portugal": "🇵🇹", "Pays-Bas": "🇳🇱", "Belgique": "🇧🇪",
        "Brésil": "🇧🇷", "Argentine": "🇦🇷", "Uruguay": "🇺🇾", "Colombie": "🇨🇴",
        "États-Unis": "🇺🇸", "Canada": "🇨🇦", "Mexique": "🇲🇽", "Sénégal": "🇸🇳",
        "Côte d'Ivoire": "🇨🇮", "Cameroun": "🇨🇲", "Nigeria": "🇳🇬", "Maroc": "🇲🇦",
        "Algérie": "🇩🇿", "Tunisie": "🇹🇳", "Égypte": "🇪🇬", "Japon": "🇯🇵",
        "Corée du Sud": "🇰🇷", "Australie": "🇦🇺", "Émirats Arabes Unis": "🇦🇪",
        "Arabie Saoudite": "🇸🇦", "Turquie": "🇹🇷", "Croatie": "🇭🇷", "Suède": "🇸🇪",
        "Norvège": "🇳🇴", "Danemark": "🇩🇰", "Écosse": "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "Autriche": "🇦🇹",
        "Suisse": "🇨🇭", "Grèce": "🇬🇷", "Chili": "🇨🇱", "Équateur": "🇪🇨",
        "Afrique du Sud": "🇿🇦", "Chine": "🇨🇳", "Qatar": "🇶🇦",
        "Nouvelle-Zélande": "🇳🇿", "Monaco": "🇲🇨",
    ]
    return flags[nation] ?? "🏳️"
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
        case .leaderNe: return "flag.fill"
        case .joueurEnRetrait: return "eye.slash.fill"
        case .mercenaire: return "eurosign.circle.fill"
        case .guerrier: return "shield.fill"
        case .showman: return "megaphone.fill"
        case .talentBrut: return "sparkles"
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
    /// Optional handle the player types in once the career is over, used to sign their entry
    /// in the local leaderboard. Empty until then; defaulted so old saves still decode.
    var alias: String = ""
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
    /// Les journées jouées par le club cette saison, que le joueur soit entré ou non. C'est le
    /// dénominateur de tout ce qui se juge en part de temps de jeu — plus aucun seuil n'est un
    /// nombre de matchs en dur. Optionnel : les anciennes sauvegardes le relisent à nil.
    var seasonFixtures: Int? = nil
    var seasonStoryEvents = 0
    /// Les rendez-vous déjà servis cette saison — grand match, étape de légende. Chacun retire
    /// une scène ordinaire au compteur. Optionnel : les anciennes sauvegardes le relisent à nil.
    var seasonBeats: Int? = nil
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

    /// Le club où la carrière a commencé, pour pouvoir y revenir en fin de parcours.
    /// Facultatif : les sauvegardes antérieures se relisent sans casse.
    var originClubId: String? = nil

    /// Le talent tiré au lancement de la carrière, identifiant d'un `FDTalentTier`. Deux
    /// carrières lancées avec les mêmes étoiles n'ont pas le même plafond ni la même vitesse
    /// de progression : c'est ce tirage qui fait qu'on ne sait jamais à quoi s'attendre.
    /// Facultatif pour que les sauvegardes antérieures se relisent sans casse.
    var talentTier: String? = nil

    /// À quel point cette carrière-là est cyclique. Tiré au lancement, propre au joueur :
    /// certaines carrières avancent d'un pas régulier, d'autres alternent les années
    /// blanches et les années de feu. Il élargit ou resserre à la fois l'humeur devant le
    /// but et la vitesse de progression, si bien que deux carrières identiques sur le papier
    /// ne racontent pas la même histoire.
    var careerVolatility: Double? = nil

    /// Le petit quelque chose devant le but qui ne se lit dans aucune statistique : il y a
    /// des joueurs qui mettent celles qu'il faut et d'autres qui les manquent. Tiré une fois,
    /// pour toute la carrière.
    var finishingEdge: Double? = nil

    /// L'humeur de la saison en cours devant le but, tirée au premier match de l'année et
    /// gardée jusqu'au bilan. Facultatif : une sauvegarde antérieure la tire à sa reprise.
    var seasonMood: Double? = nil

    /// Le potentiel choisi au départ, en demi-étoiles. Sous les quatre demi-étoiles acquises,
    /// la carrière a été volontairement handicapée : la retraite en tient compte au moment de
    /// compter les points. Facultatif, pour que les sauvegardes antérieures se relisent.
    var startHalfStars: Int? = nil

    /// Combien de grands rendez-vous cette saison-là mérite : zéro, un, parfois deux. Toutes
    /// les saisons n'ont pas leur grand soir, et une année de folie peut en avoir deux.
    /// Tirés une fois par saison ; facultatifs pour les sauvegardes antérieures.
    var seasonClimaxTarget: Int? = nil
    var seasonClimaxDone: Int? = nil

    /// Comment la carrière s'est terminée — le corps, le banc, le sommet, l'âge. Deux
    /// carrières ne doivent pas s'arrêter de la même façon ni au même âge.
    var retireReason: String? = nil

    /// Les semaines d'indisponibilité qu'il reste à purger. Le club joue sans lui, et ça se
    /// voit ensuite partout : temps de jeu, confiance du coach, progression, mercato.
    var injuryWeeks: Int? = nil

    /// Ce que les blessures passées ont laissé. Chaque grosse blessure rend la suivante plus
    /// probable — un corps abîmé ne redevient jamais neuf.
    var fragility: Int? = nil

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
    /// Un choix de mercato qui fait réellement changer de maillot : le club est appliqué au
    /// joueur, avec la ligne de transfert et la prime qui vont avec.
    var setClub: FDClub? = nil
    /// La prime encaissée si ce choix déclenche le transfert.
    var transferFee: Int? = nil
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
    /// Reserved for careers played as a "Gloire du Passé" challenge: these scenes speak of
    /// the legend being chased, and never appear in an ordinary career.
    var legendOnly: Bool = false
    /// Marque une scène de rendez-vous, qui ne sort jamais au tirage ordinaire : "climax"
    /// pour le grand match de la saison, tiré une fois par saison dans le dernier quart.
    var beat: String? = nil
    /// Le thème du rendez-vous — "club", "coupe", "europe", "selection", "derby" — dont la
    /// part change avec la carrière : un joueur de réserve ne joue pas de finale européenne.
    var beatTheme: String? = nil
}

enum FDCurrentScene {
    case none
    case story(FDSceneDef)
    case match(FDMatchResult)
    case season(FDSeasonReport)
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
    var position = FDPosition.milieu
    var personality = FDPersonality.ambitieux
    var style = FDStyle.technicien
    var background = FDBackground.stable
    var difficulty = FDDifficulty.normal
    /// Competences carried into this career, capped at FDMaxEquippedCompetences.
    var equippedCompetenceIDs: [String] = []
    var mode = FDMode.narratif
    /// Le potentiel de départ, en demi-étoiles. Il part des deux étoiles acquises et se
    /// déplace dans les deux sens : vers le haut en dépensant des points, vers le bas
    /// gratuitement, pour se compliquer volontairement la vie.
    var potentialHalfStars = FDPotentialShop.freeHalfStars
    var club: FDClub? = nil
}

/// Lifetime points earned from past careers can be spent, at creation, on "potential stars"
/// that raise the ceiling of the new player — a crack always starts modest, but experience
/// (i.e. points banked from previous careers) lets you start stronger and faster.
enum FDPotentialShop {
    /// Tout se compte en demi-étoiles : le jeu en affiche des moitiés partout ailleurs, il
    /// n'y avait pas de raison que le potentiel de départ soit le seul à s'acheter par
    /// crans entiers.
    static let maxHalfStars = 10          // cinq étoiles
    static let freeHalfStars = 4          // deux étoiles, le point de départ de toute carrière

    /// Ce qu'on peut encore remplir au-dessus du départ.
    static var buyableHalfStars: Int { maxHalfStars - freeHalfStars }

    static let maxStars = 5
    static let freeStars = 2

    /// Ce que coûte la n-ième demi-étoile achetée au-dessus du départ : chacune un peu plus
    /// cher que la précédente.
    static func costOfHalfStar(_ n: Int) -> Int { 5 * n }

    /// Le total dépensé pour n demi-étoiles au-dessus du départ.
    static func cumulativeCost(halfStars n: Int) -> Int {
        guard n > 0 else { return 0 }
        return (1...n).reduce(0) { $0 + costOfHalfStar($1) }
    }

    /// Combien de demi-étoiles ce solde de points peut remplir, au-dessus du départ.
    static func maxAffordableHalfStars(points: Int) -> Int {
        var n = 0
        while n < buyableHalfStars && cumulativeCost(halfStars: n + 1) <= points { n += 1 }
        return n
    }

    /// « 2 », « 2,5 » — pour l'affichage, à la française.
    static func label(halfStars n: Int) -> String {
        n % 2 == 0 ? "\(n / 2)" : "\(n / 2),5"
    }

    /// Les étoiles, en nombre décimal, pour tous les calculs du moteur.
    static func stars(halfStars n: Int) -> Double { Double(n) / 2 }
}

// MARK: - Chroniques

/// Everything the end-of-season screen shows: a written piece, the four figures that
/// summarise the year, and the event lines the engine produced along the way.
struct FDSeasonReport {
    var headline: String
    var article: String
    var apps: Int
    var goals: Int
    var assists: Int
    var rating: Double
    var leaguePosition: Int
    var club: String
    var seasonLabel: String
    var lines: [String]
}

/// Writes the season up as a short press piece rather than a list of numbers. The tone
/// follows the year the player actually had, and the phrasing is drawn from several
/// variants so two seasons never read exactly alike.
func fdSeasonChronicle(player p: FDPlayer, apps: Int, goals: Int, assists: Int,
                       rating: Double, leaguePosition: Int, titles: [String]) -> (headline: String, article: String) {
    let name = "\(p.firstName) \(p.lastName)"
    let club = p.club.name
    let attacking = p.position == .attaquant || p.position == .milieu

    // How the season went, on one axis, so the headline and the body agree with each other.
    enum Tone { case triumph, strong, correct, difficult, lost }
    let tone: Tone
    if !titles.isEmpty || (rating >= 7.4 && apps >= 20) {
        tone = .triumph
    } else if rating >= 7.0 && apps >= 15 {
        tone = .strong
    } else if apps < 8 {
        tone = .lost
    } else if rating >= 6.5 {
        tone = .correct
    } else {
        tone = .difficult
    }

    let headline: String
    switch tone {
    case .triumph:
        headline = [
            "Le sacre de \(name) : une saison à part",
            "\(name), la saison qui change une carrière",
            "\(club) tient son homme : la saison référence de \(name)",
        ].randomElement()!
    case .strong:
        headline = [
            "\(name) s'installe : la saison de la confirmation",
            "Régulier, décisif : \(name) a passé un cap",
            "\(name), le patron discret de \(club)",
        ].randomElement()!
    case .correct:
        headline = [
            "\(name), une saison sans éclat mais sans faute",
            "Entre bons matchs et soirées grises : la saison de \(name)",
            "\(name) a tenu son rang, sans plus",
        ].randomElement()!
    case .difficult:
        headline = [
            "Doutes et remises en question : l'année compliquée de \(name)",
            "\(name) n'a jamais trouvé son rythme",
            "Saison à oublier pour \(name)",
        ].randomElement()!
    case .lost:
        headline = [
            "Banc, tribunes, doutes : l'hiver sans fin de \(name)",
            "\(name), une saison passée à attendre son tour",
            "Le temps long : \(name) a joué au compte-gouttes",
        ].randomElement()!
    }

    var body = ""
    switch tone {
    case .triumph:
        body = "\(name) a écrit l'une de ces saisons dont on reparle des années plus tard. \(apps) matchs, une note moyenne de \(String(format: "%.1f", rating)), et un poids sur le jeu de \(club) que personne ne conteste plus."
        if !titles.isEmpty {
            body += " Le vestiaire y a gagné " + (titles.count > 1 ? "plusieurs trophées" : "un trophée") + ", et \(p.firstName) y a gagné une réputation."
        }
    case .strong:
        body = "Saison pleine pour \(name). \(apps) apparitions, \(String(format: "%.1f", rating)) de moyenne : le genre d'année qui ne fait pas les gros titres chaque semaine, mais qui construit une carrière."
    case .correct:
        body = "\(name) a fait le travail sans jamais s'échapper. \(apps) matchs pour \(String(format: "%.1f", rating)) de moyenne : correct, régulier, mais on l'attend encore ailleurs."
    case .difficult:
        body = "Rien n'est vraiment venu cette saison. \(apps) matchs, \(String(format: "%.1f", rating)) de moyenne, et une impression tenace de course après le rythme. \(club) a vu passer un joueur en dessous de ce qu'il vaut."
    case .lost:
        body = "\(apps) matchs seulement : la saison de \(name) s'est jouée surtout depuis le banc. Les semaines d'entraînement sans récompense finissent par peser, et le moral avec."
    }

    if attacking && goals + assists > 0 {
        body += " Bilan offensif : \(goals) but\(goals > 1 ? "s" : "") et \(assists) passe\(assists > 1 ? "s" : "") décisive\(assists > 1 ? "s" : "")."
    }
    if leaguePosition == 1 {
        body += " \(club) termine champion."
    } else if leaguePosition > 0 {
        body += " \(club) finit \(leaguePosition)\(leaguePosition == 1 ? "er" : "e") du championnat."
    }

    return (headline, body)
}

/// The piece that closes a career, written from everything it accumulated.
func fdCareerChronicle(player p: FDPlayer) -> (headline: String, article: String) {
    let name = "\(p.firstName) \(p.lastName)"
    let ballons = p.awardCounts[FDAward.ballonDor.rawValue] ?? 0
    let seasons = p.history.count
    let avg = p.history.isEmpty
        ? 0.0
        : p.history.reduce(0.0) { $0 + $1.avgRating } / Double(p.history.count)
    let trophies = p.leagueTitles + p.cupTitles

    // La façon dont ça s'arrête passe avant le palmarès : un genou qui lâche à vingt-six ans
    // ne se raconte pas comme une fin de parcours à trente-huit.
    let headline: String
    if p.retireReason == "blessure" {
        headline = "\(name) contraint à l'arrêt : le corps a tranché"
    } else if p.retireReason == "banc" {
        headline = "\(name) s'en va sans bruit"
    } else if p.retireReason == "sommet" && trophies > 0 {
        headline = "\(name) raccroche au sommet"
    } else if ballons > 0 {
        headline = "\(name) raccroche : la carrière d'un joueur d'exception"
    } else if trophies >= 4 {
        headline = "\(name) tire sa révérence, les mains pleines"
    } else if trophies > 0 {
        headline = "\(name) s'arrête : une carrière honorée"
    } else if seasons >= 12 {
        headline = "\(name) raccroche après \(seasons) saisons de métier"
    } else {
        headline = "\(name) met un terme à sa carrière"
    }

    var body = "\(seasons) saison\(seasons > 1 ? "s" : "") professionnelle\(seasons > 1 ? "s" : ""), \(p.careerApps) matchs, \(p.careerGoals) but\(p.careerGoals > 1 ? "s" : "") et \(p.careerAssists) passe\(p.careerAssists > 1 ? "s" : "") décisive\(p.careerAssists > 1 ? "s" : ""), pour une note moyenne de \(String(format: "%.1f", avg))."

    if trophies > 0 {
        body += " Au palmarès : \(p.leagueTitles) titre\(p.leagueTitles > 1 ? "s" : "") de champion et \(p.cupTitles) coupe\(p.cupTitles > 1 ? "s" : "")."
    } else {
        body += " Aucun grand trophée, mais une carrière tenue au bout."
    }
    if ballons > 0 {
        body += " Et \(ballons) Ballon\(ballons > 1 ? "s" : "") d'Or, ce que presque personne n'atteint."
    }
    if p.nationalCaps > 0 {
        body += " \(p.nationalCaps) sélection\(p.nationalCaps > 1 ? "s" : "") avec \(p.nationality)."
    }
    body += " Parti de \(p.birthCity), \(p.firstName) termine à \(p.age) ans, sous le maillot de \(p.club.name)."
    switch p.retireReason {
    case "blessure":
        body += " Ce n'est pas lui qui a choisi la date : une blessure de trop, un avis médical, et une carrière qui s'arrête au milieu d'une phrase."
    case "banc":
        body += " Il n'y aura pas eu de match d'adieu. Les derniers mois se sont passés loin du terrain, et le communiqué tient en trois lignes."
    case "sommet":
        body += " Il part sur un trophée, ce que presque personne ne réussit : décider soi-même de sa dernière image."
    default:
        break
    }

    return (headline, body)
}

// MARK: - Conséquence d'un choix

/// Une scène écrite peut fournir sa propre suite (`hint`), et les meilleures le font. Pour
/// toutes les autres, l'écran de résultat n'affichait que des pastilles chiffrées : on
/// voyait ce qui avait bougé, jamais ce qui s'était passé. Ces fragments recomposent la
/// conséquence en français à partir de ce que le choix a réellement changé — le levier qui
/// monte le plus, celui qui descend le plus — avec assez de variantes pour qu'on ne relise
/// pas deux fois la même phrase.
private let fdConsequenceUp: [String: [String]] = [
    "tech":       ["ton pied répond mieux qu'avant", "le ballon te colle enfin au pied", "ta technique passe un cran"],
    "phys":       ["ton corps suit sans broncher", "tu tiens des efforts qui te coupaient les jambes", "physiquement, tu prends le dessus"],
    "ment":       ["ta tête reste froide quand ça chauffe", "tu joues avec une lucidité nouvelle", "tu ne trembles plus dans les moments qui comptent"],
    "def":        ["tu sens le danger avant les autres", "tu lis le jeu adverse une seconde en avance", "défensivement, plus rien ne te surprend"],
    "forme":      ["tu te sens bien dans tes jambes", "ta forme repart nettement", "tu arrives frais aux séances"],
    "moral":      ["tu marches plus léger", "tu retrouves le plaisir de venir travailler", "le moral remonte pour de bon"],
    "confiance":  ["tu oses des choses que tu n'osais pas", "la confiance revient d'un coup", "tu joues sans te poser de questions"],
    "reputation": ["on commence à parler de toi ailleurs", "ton nom circule au-delà du club", "ta cote grimpe"],
    "fatigue":    ["tu récupères enfin", "les jambes se dénouent", "tu redémarres la semaine sans traîner"],
    "coach":      ["le coach note la réponse", "tu montes d'un cran dans son estime", "il te regarde autrement"],
    "staff":      ["le staff te fait davantage confiance", "les kinés et les préparateurs jouent le jeu avec toi", "on t'accompagne mieux au quotidien"],
    "president":  ["le président apprécie", "la direction te met du côté des siens", "en haut, on te trouve sérieux"],
    "agent":      ["ton agent y voit clair", "il pousse ton dossier avec plus d'énergie", "il te sent enfin décidé"],
    "capitaine":  ["le capitaine te prend au sérieux", "il te met dans son cercle", "il te consulte désormais"],
    "vestiaire":  ["le vestiaire retient le geste", "le groupe te suit", "on te compte parmi les leurs"],
    "famille":    ["à la maison, on respire", "les tiens sont derrière toi", "la famille se sent enfin considérée"],
    "partenaire": ["chez toi, l'ambiance s'apaise", "on te soutient sans arrière-pensée", "ta vie privée redevient un appui"],
    "media":      ["la presse t'accorde le bénéfice du doute", "les journalistes te trouvent une bonne tête", "le traitement médiatique tourne en ta faveur"],
    "fans":       ["les tribunes te le rendent", "ton nom sort du virage à chaque échauffement", "les supporters t'adoptent"],
    "money":      ["le compte grossit", "l'opération rapporte", "le portefeuille s'en trouve mieux"],
]

private let fdConsequenceDown: [String: [String]] = [
    "tech":       ["ton geste se dérègle", "tu perds des ballons que tu ne perdais pas", "la technique en prend un coup"],
    "phys":       ["le corps encaisse mal", "tu finis les matchs à l'arraché", "physiquement, tu recules"],
    "ment":       ["tu te crispes dès que ça compte", "la tête suit moins bien", "tu prends de mauvaises décisions dans l'urgence"],
    "def":        ["tu prends un temps de retard sur le danger", "tu te fais prendre dans le dos", "ta lecture défensive s'égare"],
    "forme":      ["la forme en prend un coup", "les jambes ne répondent plus pareil", "tu joues à l'économie"],
    "moral":      ["ça te reste en travers", "le moral en prend un coup", "tu traînes ça toute la semaine"],
    "confiance":  ["tu doutes au moment de tenter", "la confiance s'effrite", "tu joues la sécurité maintenant"],
    "reputation": ["ton image en pâtit", "on retiendra surtout ça de toi", "ta cote en prend un coup"],
    "fatigue":    ["tu le paies dans les jambes", "la fatigue s'installe", "tu récupères de moins en moins vite"],
    "coach":      ["le coach ne l'oublie pas", "il t'en tient rigueur", "tu redescends dans sa hiérarchie"],
    "staff":      ["le staff fait la tête", "on t'accompagne du bout des doigts", "les portes du staff se referment un peu"],
    "president":  ["en haut, ça grince", "la direction s'en souvient", "le président prend note, et pas dans le bon sens"],
    "agent":      ["ton agent le prend mal", "il lève le pied sur ton dossier", "il ne comprend pas ta logique"],
    "capitaine":  ["le capitaine te bat froid", "il ne te couvre plus", "il te met à distance"],
    "vestiaire":  ["le vestiaire tique", "le groupe met une distance", "on te le fait sentir aux repas"],
    "famille":    ["à la maison, ça pèse", "les tiens ne comprennent pas", "la famille encaisse en silence"],
    "partenaire": ["chez toi, ça se tend", "on te reproche de ne jamais être là", "ta vie privée en pâtit"],
    "media":      ["la presse s'en empare", "les titres ne sont pas tendres", "les journalistes te taillent"],
    "fans":       ["les tribunes te le font savoir", "le virage siffle ton nom", "les supporters ne suivent plus"],
    "money":      ["l'argent part", "ça coûte cher", "le compte encaisse"],
]

private func fdLever(_ e: FDEffect) -> String? {
    if let attr = e.attr { return attr.category.rawValue }
    if let cond = e.cond { return cond }
    if let rel = e.rel { return rel }
    if e.money != nil { return "money" }
    return nil
}

/// L'ampleur d'un effet, ramenée à une même échelle : l'argent se compte en milliers.
private func fdMagnitude(_ e: FDEffect) -> Int {
    if let money = e.money { return abs(money) / 4000 }
    // La fatigue est le seul levier dont la hausse dessert le joueur.
    return abs(e.delta)
}

private func fdIsGain(_ e: FDEffect) -> Bool {
    if let money = e.money { return money > 0 }
    if e.cond == "fatigue" { return e.delta < 0 }
    return e.delta > 0
}

/// Recompose la suite d'un choix : le gain le plus fort, le prix le plus fort, en une phrase.
func fdConsequence(effects: [FDEffect], seed: Int) -> String {
    let scored = effects.filter { fdLever($0) != nil && fdMagnitude($0) > 0 }
    guard !scored.isEmpty else { return "" }

    let gains = scored.filter { fdIsGain($0) }.sorted { fdMagnitude($0) > fdMagnitude($1) }
    let costs = scored.filter { !fdIsGain($0) }.sorted { fdMagnitude($0) > fdMagnitude($1) }

    func fragment(_ e: FDEffect, up: Bool, offset: Int) -> String? {
        guard let lever = fdLever(e) else { return nil }
        let bank = up ? fdConsequenceUp : fdConsequenceDown
        guard let variants = bank[lever], !variants.isEmpty else { return nil }
        return variants[abs(seed &+ offset) % variants.count]
    }

    let gain = gains.first.flatMap { fragment($0, up: true, offset: 0) }
    let cost = costs.first.flatMap { fragment($0, up: false, offset: 7) }

    switch (gain, cost) {
    case let (g?, c?):
        // Le prix en second : c'est ce que le joueur doit retenir en refermant la carte.
        return (g.prefix(1).uppercased() + g.dropFirst()) + ", mais " + c + "."
    case let (g?, nil):
        return (g.prefix(1).uppercased() + g.dropFirst()) + "."
    case let (nil, c?):
        return (c.prefix(1).uppercased() + c.dropFirst()) + "."
    default:
        return ""
    }
}


// MARK: - Talent

/// Un palier de talent, tiré une fois au lancement de la carrière et jamais annoncé.
struct FDTalentTier {
    let id: String
    let label: String
    /// Ce que le palier ajoute (ou retire) au plafond de progression.
    let potentialBias: Int
    /// Le pas de progression maximal d'un attribut sur une saison.
    let growthStep: Int
    /// Multiplie la vitesse de progression liée à l'âge.
    let growthFactor: Double
    /// Le poids de base du palier dans le tirage, avant l'effet des étoiles achetées.
    let weight: Double
    /// La ligne que le journal écrit quand la carrière révèle enfin de quel bois elle est faite.
    let reveal: String
}

/// Une carrière rate, tient la route, ou explose — et la dernière possibilité reste rare,
/// sinon il n'y aurait plus rien à découvrir en relançant.
let FDTalentTiers: [FDTalentTier] = [
    FDTalentTier(id: "tardif", label: "Tardif", potentialBias: -7, growthStep: 2, growthFactor: 0.85, weight: 18,
                 reveal: "Le staff te trouve en retard sur ta génération. Tout ce que tu prendras, tu iras le chercher."),
    FDTalentTier(id: "ordinaire", label: "Ordinaire", potentialBias: 0, growthStep: 3, growthFactor: 1.0, weight: 46,
                 reveal: "Le club te situe dans la moyenne de ta génération : ni révélation, ni cas désespéré."),
    FDTalentTier(id: "prometteur", label: "Prometteur", potentialBias: 7, growthStep: 3, growthFactor: 1.15, weight: 27,
                 reveal: "En interne, on commence à parler de toi comme d'un des bons éléments de ta génération."),
    FDTalentTier(id: "pepite", label: "Pépite", potentialBias: 16, growthStep: 4, growthFactor: 1.35, weight: 7,
                 reveal: "Les recruteurs se déplacent pour toi. Le mot « pépite » est lâché, et il ne l'est pas souvent."),
    FDTalentTier(id: "generation", label: "Génération", potentialBias: 26, growthStep: 5, growthFactor: 1.6, weight: 2,
                 reveal: "On te compare à des joueurs qui n'apparaissent qu'une fois tous les dix ans. Personne n'avait vu ça venir."),
]

/// Le tirage du talent. Les étoiles achetées ne garantissent rien : elles déplacent la
/// chance, en poussant les paliers hauts et en vidant le palier tardif. Une carrière peut
/// donc exploser sans une seule étoile — rarement, mais elle le peut.
/// `starsBought` peut être négatif : descendre sous les deux étoiles de départ ne fait pas
/// que baisser le plafond, ça rend aussi les bons paliers plus rares et le palier tardif
/// plus probable. Une carrière handicapée est vraiment plus dure, pas seulement plus lente.
func fdDrawTalentTier(starsBought: Double) -> FDTalentTier {
    let stars = starsBought
    // Le handicap frappe plus fort que le bonus n'aide : partir sous les deux étoiles divise
    // presque par deux la chance de tomber sur un grand palier. C'est ce qui rend une carrière
    // à zéro étoile vraiment difficile, et pas seulement plus lente.
    let down = stars < 0 ? stars * 3.5 : 0
    var pool: [(FDTalentTier, Double)] = []
    for tier in FDTalentTiers {
        var weight = tier.weight
        switch tier.id {
        case "tardif": weight = max(3, weight - stars * 2.1)
        case "prometteur": weight = max(2, weight + stars * 1.5 + down)
        case "pepite": weight = max(0.5, weight + stars * 0.5 + down * 0.4)
        case "generation": weight = max(0.2, weight + stars * 0.1 + down * 0.15)
        default: break
        }
        pool.append((tier, weight))
    }
    let total = pool.reduce(0.0) { $0 + $1.1 }
    var roll = Double.random(in: 0..<total)
    for (tier, weight) in pool {
        if roll < weight { return tier }
        roll -= weight
    }
    return pool[1].0
}

func fdTalentTier(_ id: String?) -> FDTalentTier {
    FDTalentTiers.first { $0.id == id } ?? FDTalentTiers[1]
}

/// La phrase qui referme une carrière. Elle dit pourquoi elle s'arrête là, parce que la
/// raison n'est jamais la même : le corps, le banc, un sommet dont on ne redescend pas, ou
/// simplement les années.
func fdRetirementLine(reason: String, age: Int, club: String) -> String {
    switch reason {
    case "blessure":
        return "🩼 Fin de carrière à \(age) ans. Le corps a dit non, et cette fois il n'y avait rien à négocier : "
            + "les médecins ont été clairs, tu ne rejoueras pas. Ça ne se termine pas comme tu l'avais imaginé."
    case "banc":
        return "🚪 Fin de carrière à \(age) ans. Tu n'as plus joué depuis des mois, personne n'a rappelé, "
            + "et un matin tu as compris que c'était déjà fini depuis un moment. Tu raccroches sans annonce."
    case "sommet":
        return "👑 Fin de carrière à \(age) ans, sur un trophée. Peu de joueurs choisissent leur dernière image : "
            + "tu viens de le faire, et \(club) ne l'oubliera pas."
    default:
        return "🎓 Fin de carrière à \(age) ans. Tu as tout donné à ce jeu, il t'a rendu ce qu'il pouvait, "
            + "et l'heure est venue de rendre le maillot à \(club)."
    }
}

// MARK: - Récit d'un grand rendez-vous

/// Le nom du rendez-vous, tel qu'on l'annonce.
private func fdBigMatchLabel(_ theme: String) -> String {
    switch theme {
    case "coupe": return "la finale de coupe"
    case "coupe_petit": return "le grand soir de coupe"
    case "europe": return "la soirée européenne"
    case "selection": return "le match avec la sélection"
    case "derby": return "le derby"
    default: return "le match"
    }
}

/// Le lendemain d'un grand rendez-vous, écrit comme un entrefilet de presse : le résultat,
/// la part qu'y a prise le joueur, et surtout ce que la soirée change pour lui. Pas de note,
/// pas de ligne de statistiques — une finale se juge à ses répercussions, pas à un chiffre
/// sur dix.
func fdBigMatchReport(_ r: FDMatchResult, theme: String, player p: FDPlayer) -> String {
    let label = fdBigMatchLabel(theme)
    let club = p.club.name
    let name = p.lastName
    let score = "\(r.teamScore)-\(r.oppScore)"
    let won = r.teamScore > r.oppScore
    let drew = r.teamScore == r.oppScore
    // Une variante sur deux, pour que deux finales de suite ne se racontent pas pareil.
    let alt = (r.goals + r.assists + r.minutes) % 2 == 0

    // Resté sur le banc : le résultat le concerne quand même, et c'est bien le problème.
    if r.minutes == 0 {
        if won {
            return alt
                ? "\(club) gagne \(score) pour \(label). Le vestiaire chante, les images tournent en boucle, et sur toutes les photos \(name) porte encore le survêtement. On fête une soirée qu'on n'a pas vécue : personne, demain, n'associera son nom à celle-là."
                : "\(club) s'impose \(score) pour \(label). \(name) n'a pas quitté le banc. Le titre est là, la joie aussi, mais il repart avec la sensation d'avoir regardé sa propre équipe écrire quelque chose sans lui — et ça, ça travaille un joueur pendant des semaines."
        }
        if drew {
            return alt
                ? "\(score) pour \(label), et rien n'est tranché. En conférence, on demande à l'entraîneur pourquoi \(name) n'est pas entré quand le match réclamait autre chose. Il répond qu'il a fait des choix. La question va tourner toute la semaine."
                : "\(score) : \(club) repart de \(label) sans avoir rien réglé. \(name) s'est échauffé trois fois, il n'est jamais entré. Dans les journaux du matin, son nom apparaît une seule fois, en bas de feuille de match, dans la liste des remplaçants."
        }
        return alt
            ? "\(club) s'incline \(score) pour \(label). \(name) a tout regardé depuis le banc, et c'est exactement ce que la presse retient : une équipe à court d'idées et une solution laissée de côté. Ce sont ces soirs-là qui rouvrent une porte."
            : "Défaite \(score) pour \(label). \(name) n'a pas joué une minute. L'entraîneur sortira fragilisé de cette soirée, et un entraîneur fragilisé change son onze : la semaine qui vient vaudra plus que le match d'hier."
    }

    var out = won
        ? "\(club) l'emporte \(score) pour \(label)."
        : (drew ? "\(score) pour \(label) : personne n'a pris l'avantage."
                : "\(club) tombe \(score) pour \(label).")

    // Sa part de la soirée, racontée comme un journaliste la raconterait.
    if r.goals >= 2 {
        out += " \(name) en a mis \(r.goals), et c'est son nom qui ouvre tous les papiers du matin."
    } else if r.goals == 1 {
        out += r.assists > 0
            ? " Un but, une passe : la soirée est passée par \(name)."
            : " Le but est de \(name)."
    } else if r.assists > 0 {
        out += " La passe décisive est signée \(name)."
    } else if r.rating >= 7 {
        out += " \(name) n'apparaît pas sur la feuille de but, mais ceux qui étaient là ont vu qui tenait l'équipe debout."
    } else {
        out += " \(name), lui, n'a jamais trouvé le match."
    }

    if r.red {
        out += " Son carton rouge est déjà l'image de la soirée, et il paiera l'addition au prochain rendez-vous."
    } else if r.yellow {
        out += " Un jaune l'a obligé à jouer la deuxième période sur un fil."
    }
    if r.injury { out += " Il est sorti en se tenant la jambe ; le staff parlera demain." }

    // La seule chose qui compte vraiment : ce que cette soirée laisse derrière elle.
    let peserContribue = r.goals > 0 || r.assists > 0 || r.rating >= 7
    if won {
        out += peserContribue
            ? (alt
                ? " Ce matin, la ville n'a pas dormi et il y a une photo de lui en première page. C'est comme ça qu'on entre dans une histoire de club : une soirée, et on ne vous regarde plus jamais de la même façon."
                : " Le président est descendu au vestiaire. L'entraîneur a dit devant les micros qu'on tenait là un joueur pour les grands soirs, et une phrase pareille, dans ce club, ça vaut un contrat.")
            : (alt
                ? " La fête est pour tout le monde, la une pour un autre. Il a gagné, il a le trophée, et il sait très bien qu'il ne doit rien à sa propre soirée."
                : " Le résultat efface tout, y compris les performances moyennes. Il repart avec un titre et l'idée tenace qu'il aurait dû être celui dont on parle.")
    } else if drew {
        out += peserContribue
            ? " Le nul laisse tout ouvert, mais son nom, lui, ressort grandi : dans une soirée sans vainqueur, il est le seul dont on aura parlé."
            : " Un match nul ne fâche personne et ne sauve personne. La semaine s'annonce longue, et les places seront rediscutées à l'entraînement."
    } else {
        out += peserContribue
            ? (alt
                ? " Il n'y a pas de consolation dans une défaite pareille, mais il y a des joueurs qui en sortent grandis. Les journaux le mettent hors du procès général : on lui reconnaît d'avoir été le dernier debout."
                : " L'équipe va prendre cher toute la semaine, lui beaucoup moins. Ce genre de soirée, perdue mais tenue, se retient plus longtemps qu'une victoire tranquille.")
            : (alt
                ? " Le lendemain est violent : les supporters attendent au centre d'entraînement, et les questions ne portent pas sur le collectif. On cite des noms, et le sien en fait partie."
                : " Une défaite pareille laisse des traces. Le vestiaire va chercher des responsables, et il n'a rien fait, hier soir, pour ne pas être dans la liste.")
    }
    return out
}

/// La ligne courte qui entre au journal de carrière.
func fdBigMatchHeadline(_ r: FDMatchResult, theme: String) -> String {
    let label = fdBigMatchLabel(theme)
    let issue = r.teamScore > r.oppScore ? "Victoire" : (r.teamScore == r.oppScore ? "Nul" : "Défaite")
    var line = "\(issue) \(r.teamScore)-\(r.oppScore) sur \(label)"
    if r.goals > 0 { line += ", \(r.goals) but\(r.goals > 1 ? "s" : "")" }
    if r.assists > 0 { line += ", \(r.assists) passe décisive" }
    return line + "."
}
