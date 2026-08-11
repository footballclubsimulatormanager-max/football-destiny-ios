import Foundation

// MARK: - Boutique (permanent shop unlocks, paid with legend coins)

enum FDCompetenceEffect: Hashable {
    case reputation(Int)
    case money(Int)
    case forme(Int)
    case confiance(Int)
    case moral(Int)
    case potential(Int)
}

struct FDCompetence: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let cost: Int
    let effect: FDCompetenceEffect
}

let FDCompetences: [FDCompetence] = [
    FDCompetence(id: "reputation_1", name: "Œil du recruteur", icon: "👁️", description: "Ta réputation de départ est un peu plus solide.", cost: 5, effect: .reputation(5)),
    FDCompetence(id: "money_1", name: "Filière familiale", icon: "💰", description: "Un petit pécule en plus pour démarrer.", cost: 4, effect: .money(1000)),
    FDCompetence(id: "forme_1", name: "Préparation physique", icon: "💪", description: "Tu arrives en pro dans une forme excellente.", cost: 4, effect: .forme(8)),
    FDCompetence(id: "confiance_1", name: "Mental de compétiteur", icon: "🧠", description: "Une confiance en toi déjà bien ancrée.", cost: 4, effect: .confiance(8)),
    FDCompetence(id: "moral_1", name: "Entourage solide", icon: "🤝", description: "Un moral au beau fixe dès le premier jour.", cost: 4, effect: .moral(8)),
    FDCompetence(id: "potential_1", name: "Formation héritée", icon: "🌟", description: "Ton potentiel de départ grimpe encore un peu plus.", cost: 10, effect: .potential(5)),
]

// MARK: - Défi Gloire du Passé (fictional legends, inspired by real archetypes — never real names)

struct FDLegendChallenge: Identifiable, Hashable {
    let id: String
    let name: String
    let era: String
    let nationality: String
    let position: FDPosition
    let style: FDStyle
    let personality: FDPersonality
    let archetype: String
    let unlockCost: Int
    let targetScore: Int
}

let FDLegendChallenges: [FDLegendChallenge] = [
    FDLegendChallenge(id: "legend_maestro", name: "Le Maestro", era: "Années 1990", nationality: "France", position: .milieuOffensif, style: .createur, personality: .charismatique,
                       archetype: "Le dernier geste avant le but, une carrière entière à faire jouer les autres.", unlockCost: 3, targetScore: 190),
    FDLegendChallenge(id: "legend_panthere", name: "La Panthère", era: "Années 1990", nationality: "Brésil", position: .avantCentre, style: .finisseur, personality: .ambitieux,
                       archetype: "Vitesse féline et sens du but hors normes, la terreur des défenses sud-américaines.", unlockCost: 4, targetScore: 230),
    FDLegendChallenge(id: "legend_mur_bavarois", name: "Le Mur Bavarois", era: "Années 1970", nationality: "Allemagne", position: .defenseurCentral, style: .leader, personality: .discipline,
                       archetype: "Un roc increvable, capitaine par la seule force du regard.", unlockCost: 3, targetScore: 160),
    FDLegendChallenge(id: "legend_rey", name: "El Rey", era: "Années 1980", nationality: "Argentine", position: .milieuOffensif, style: .technicien, personality: .irregulier,
                       archetype: "Génie imprévisible, capable de gagner un match à lui seul d'un coup de génie.", unlockCost: 6, targetScore: 210),
    FDLegendChallenge(id: "legend_gunner", name: "The Gunner", era: "Années 2000", nationality: "Angleterre", position: .ailier, style: .rapide, personality: .travailleur,
                       archetype: "Vitesse pure sur l'aile droite, un métronome de régularité pendant quinze ans.", unlockCost: 5, targetScore: 200),
    FDLegendChallenge(id: "legend_rei_do_gol", name: "O Rei do Gol", era: "Années 1960", nationality: "Brésil", position: .avantCentre, style: .finisseur, personality: .ambitieux,
                       archetype: "Le buteur des buteurs, une légende que même les grands-parents racontent encore.", unlockCost: 8, targetScore: 260),
    FDLegendChallenge(id: "legend_divin", name: "Il Divin", era: "Années 1990", nationality: "Italie", position: .avantCentre, style: .technicien, personality: .charismatique,
                       archetype: "Élégance italienne, un jeu de tête et une frappe qui ont marqué toute une génération.", unlockCost: 6, targetScore: 220),
    FDLegendChallenge(id: "legend_muraille_rousse", name: "La Muraille Rousse", era: "Années 1970", nationality: "Pays-Bas", position: .defenseurCentral, style: .leader, personality: .reserve,
                       archetype: "Un libéro visionnaire qui lisait le jeu deux temps d'avance sur tout le monde.", unlockCost: 4, targetScore: 175),
    FDLegendChallenge(id: "legend_pistolero", name: "El Pistolero", era: "Années 2010", nationality: "Uruguay", position: .avantCentre, style: .finisseur, personality: .provocateur,
                       archetype: "Un tempérament de feu et une efficacité clinique devant le but, saison après saison.", unlockCost: 7, targetScore: 240),
    FDLegendChallenge(id: "legend_sorcier", name: "Le Sorcier", era: "Années 1990", nationality: "Cameroun", position: .ailier, style: .createur, personality: .charismatique,
                       archetype: "Dribbles impossibles et sourire ravageur, l'idole de tout un continent.", unlockCost: 5, targetScore: 195),
    FDLegendChallenge(id: "legend_iceman", name: "The Iceman", era: "Années 2020", nationality: "Norvège", position: .avantCentre, style: .finisseur, personality: .discipline,
                       archetype: "Sang-froid absolu devant le but, une machine à statistiques de l'ère moderne.", unlockCost: 9, targetScore: 250),
    FDLegendChallenge(id: "legend_kaiser", name: "Kaiser du Milieu", era: "Années 2010", nationality: "Allemagne", position: .milieuRelayeur, style: .leader, personality: .travailleur,
                       archetype: "Le patron du milieu, celui qui fait tourner toute une génération dorée.", unlockCost: 6, targetScore: 215),
]
