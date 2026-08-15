import Foundation

// MARK: - Meta-progression economy
//
// Two currencies, deliberately different in scale:
//  • Points de carrière (lifetimePoints) — earned generously every career, spent on starting
//    potential stars during creation.
//  • Pièces (legendCoins) — earned only for the *quality* of a finished career (see
//    FDGameEngine.careerQualityCoins), roughly 1–3 for an ordinary career and 10–14 for a
//    near-perfect one. Everything below is priced against that: an average career banks about
//    3 coins, so a 40-coin item is ~12 careers of play and a 350-coin item is ~100+.
//
// Price bands used throughout this file:
//   Palier 1  ·  30–50    ≈ 10–15 careers   — first upgrades, reachable early
//   Palier 2  ·  70–120   ≈ 25–40 careers
//   Palier 3  ·  150–230  ≈ 50–75 careers
//   Palier 4  ·  300–420  ≈ 100+ careers    — the long-haul goals

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

    /// Coarse band used by the Boutique to group and colour items.
    var tier: Int {
        switch cost {
        case ..<60: return 1
        case ..<140: return 2
        case ..<260: return 3
        default: return 4
        }
    }
}

/// Alias used by the Boutique screen's redesigned UI.
typealias FDPermanentSkill = FDCompetence

let FDCompetences: [FDCompetence] = [
    // ---- Palier 1 — premières améliorations (10–15 carrières) ----
    FDCompetence(id: "reputation_1", name: "Œil du recruteur", icon: "eye.fill",
                 description: "Ta réputation de départ est un peu plus solide.", cost: 30, effect: .reputation(5)),
    FDCompetence(id: "money_1", name: "Filière familiale", icon: "eurosign.circle.fill",
                 description: "Un petit pécule pour démarrer sans compter.", cost: 32, effect: .money(1500)),
    FDCompetence(id: "forme_1", name: "Préparation physique", icon: "waveform.path.ecg",
                 description: "Tu arrives en pro dans une forme excellente.", cost: 34, effect: .forme(8)),
    FDCompetence(id: "confiance_1", name: "Mental de compétiteur", icon: "brain.fill",
                 description: "Une confiance en toi déjà bien ancrée.", cost: 34, effect: .confiance(8)),
    FDCompetence(id: "moral_1", name: "Entourage solide", icon: "hand.raised.fill",
                 description: "Un moral au beau fixe dès le premier jour.", cost: 34, effect: .moral(8)),
    FDCompetence(id: "potential_1", name: "Formation héritée", icon: "star.circle.fill",
                 description: "Ton plafond de progression grimpe légèrement.", cost: 48, effect: .potential(4)),

    // ---- Palier 2 — consolidation (25–40 carrières) ----
    FDCompetence(id: "reputation_2", name: "Buzz des réseaux", icon: "antenna.radiowaves.left.and.right",
                 description: "On parle de toi avant même ton premier match pro.", cost: 75, effect: .reputation(10)),
    FDCompetence(id: "money_2", name: "Premier sponsor", icon: "signature",
                 description: "Un équipementier local mise sur toi très tôt.", cost: 78, effect: .money(5000)),
    FDCompetence(id: "forme_2", name: "Hygiène irréprochable", icon: "bed.double.fill",
                 description: "Sommeil, nutrition, récupération : tout est déjà en place.", cost: 82, effect: .forme(14)),
    FDCompetence(id: "confiance_2", name: "Préparateur mental", icon: "figure.mind.and.body",
                 description: "Tu abordes chaque échéance avec une sérénité rare.", cost: 82, effect: .confiance(14)),
    FDCompetence(id: "moral_2", name: "Famille présente", icon: "house.fill",
                 description: "Un cocon qui encaisse les coups durs à ta place.", cost: 82, effect: .moral(14)),
    FDCompetence(id: "potential_2", name: "Centre de formation d'élite", icon: "building.columns.fill",
                 description: "Les meilleures méthodes de formation, dès le plus jeune âge.", cost: 120, effect: .potential(8)),

    // ---- Palier 3 — statut installé (50–75 carrières) ----
    FDCompetence(id: "reputation_3", name: "Pépite annoncée", icon: "sparkles",
                 description: "Toute l'Europe surveille déjà ta progression.", cost: 160, effect: .reputation(16)),
    FDCompetence(id: "money_3", name: "Agent influent", icon: "briefcase.fill",
                 description: "Ton représentant négocie mieux que les autres, depuis toujours.", cost: 165, effect: .money(15000)),
    FDCompetence(id: "forme_3", name: "Génétique privilégiée", icon: "bolt.heart.fill",
                 description: "Un corps qui encaisse là où les autres cassent.", cost: 175, effect: .forme(20)),
    FDCompetence(id: "confiance_3", name: "Nerfs d'acier", icon: "shield.lefthalf.filled",
                 description: "Les grands rendez-vous ne t'ont jamais fait trembler.", cost: 175, effect: .confiance(20)),
    FDCompetence(id: "moral_3", name: "Inébranlable", icon: "mountain.2.fill",
                 description: "Blessures, critiques, échecs : rien n'entame ton moral.", cost: 175, effect: .moral(20)),
    FDCompetence(id: "potential_3", name: "Don précoce", icon: "wand.and.stars",
                 description: "Un talent brut que les entraîneurs n'expliquent pas.", cost: 230, effect: .potential(12)),

    // ---- Palier 4 — objectifs longue haleine (100+ carrières) ----
    FDCompetence(id: "reputation_4", name: "Nom déjà légendaire", icon: "crown.fill",
                 description: "Tu portes un nom qui ouvre toutes les portes du football.", cost: 310, effect: .reputation(24)),
    FDCompetence(id: "money_4", name: "Fortune établie", icon: "banknote.fill",
                 description: "L'argent n'a jamais été, et ne sera jamais, une contrainte.", cost: 320, effect: .money(50000)),
    FDCompetence(id: "forme_4", name: "Physique hors normes", icon: "figure.run.circle.fill",
                 description: "Une machine athlétique que le calendrier n'use pas.", cost: 340, effect: .forme(26)),
    FDCompetence(id: "confiance_4", name: "Certitude absolue", icon: "checkmark.seal.fill",
                 description: "Tu n'as jamais douté une seule seconde de ta réussite.", cost: 340, effect: .confiance(26)),
    FDCompetence(id: "potential_4", name: "Génération dorée", icon: "trophy.fill",
                 description: "Le plafond de progression le plus haut que le jeu autorise.", cost: 420, effect: .potential(18)),
]

// MARK: - Défi Gloire du Passé
//
// 50 fictional legends inspired by archetypes rather than real players — no real name,
// club or likeness is used anywhere. Unlock costs follow the same price bands as the
// Boutique: the entry challenges are reachable in ~10–15 careers, the final ones take 100+.
//
// `targetScore` is compared against FDGameEngine.legendScore, which weighs goals, assists,
// silverware, individual awards and caps. For reference, a very strong career lands around
// 500–550, so the last tier is meant to require a genuinely exceptional run.

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

    var tier: Int {
        switch unlockCost {
        case ..<60: return 1
        case ..<140: return 2
        case ..<260: return 3
        default: return 4
        }
    }
}

/// Alias used by the Défis screen's redesigned UI.
typealias FDChallenge = FDLegendChallenge

let FDLegendChallenges: [FDLegendChallenge] = [
    // ================= Palier 1 — 10 défis d'entrée (30–50 pièces) =================
    FDLegendChallenge(id: "legend_mur_bavarois", name: "Le Mur Bavarois", era: "Années 1970", nationality: "Allemagne", position: .defenseur, style: .leader, personality: .discipline,
                      archetype: "Un roc increvable, capitaine par la seule force du regard.", unlockCost: 30, targetScore: 120),
    FDLegendChallenge(id: "legend_sentinelle", name: "La Sentinelle", era: "Années 1980", nationality: "Italie", position: .defenseur, style: .recuperateur, personality: .reserve,
                      archetype: "Personne n'est jamais passé dans son dos. Personne.", unlockCost: 32, targetScore: 130),
    FDLegendChallenge(id: "legend_chat", name: "Le Chat", era: "Années 1960", nationality: "France", position: .gardien, style: .technicien, personality: .reserve,
                      archetype: "Des réflexes que les attaquants de l'époque disaient surnaturels.", unlockCost: 34, targetScore: 125),
    FDLegendChallenge(id: "legend_metronome", name: "Le Métronome", era: "Années 1990", nationality: "Espagne", position: .milieu, style: .technicien, personality: .discipline,
                      archetype: "Quinze ans à donner le tempo sans jamais hausser le ton.", unlockCost: 36, targetScore: 150),
    FDLegendChallenge(id: "legend_poumon", name: "Le Poumon", era: "Années 2000", nationality: "Angleterre", position: .milieu, style: .puissant, personality: .travailleur,
                      archetype: "Il a couru plus que n'importe qui, chaque week-end, pendant une décennie.", unlockCost: 38, targetScore: 155),
    FDLegendChallenge(id: "legend_verrou", name: "Le Verrou Rouge", era: "Années 1980", nationality: "Belgique", position: .defenseur, style: .leader, personality: .travailleur,
                      archetype: "Une carrière entière au service d'une seule idée : ne pas encaisser.", unlockCost: 40, targetScore: 145),
    FDLegendChallenge(id: "legend_ailier_fou", name: "L'Ailier Fou", era: "Années 1990", nationality: "Portugal", position: .attaquant, style: .rapide, personality: .irregulier,
                      archetype: "Génial ou catastrophique, jamais entre les deux.", unlockCost: 42, targetScore: 170),
    FDLegendChallenge(id: "legend_capitaine_nord", name: "Le Capitaine du Nord", era: "Années 2000", nationality: "Danemark", position: .defenseur, style: .leader, personality: .discipline,
                      archetype: "Un brassard porté 400 matchs sans jamais le rendre.", unlockCost: 44, targetScore: 160),
    FDLegendChallenge(id: "legend_renard", name: "Le Renard des Surfaces", era: "Années 1970", nationality: "Allemagne", position: .attaquant, style: .finisseur, personality: .discipline,
                      archetype: "Toujours au bon endroit, toujours une demi-seconde avant le défenseur.", unlockCost: 46, targetScore: 185),
    FDLegendChallenge(id: "legend_maestro", name: "Le Maestro", era: "Années 1990", nationality: "France", position: .milieu, style: .createur, personality: .charismatique,
                      archetype: "Le dernier geste avant le but, une carrière entière à faire jouer les autres.", unlockCost: 50, targetScore: 190),

    // ================= Palier 2 — 14 défis intermédiaires (70–120 pièces) =================
    FDLegendChallenge(id: "legend_muraille_rousse", name: "La Muraille Rousse", era: "Années 1970", nationality: "Pays-Bas", position: .defenseur, style: .leader, personality: .reserve,
                      archetype: "Un libéro visionnaire qui lisait le jeu deux temps d'avance.", unlockCost: 70, targetScore: 200),
    FDLegendChallenge(id: "legend_gunner", name: "The Gunner", era: "Années 2000", nationality: "Angleterre", position: .attaquant, style: .rapide, personality: .travailleur,
                      archetype: "Vitesse pure sur l'aile droite, un métronome de régularité pendant quinze ans.", unlockCost: 74, targetScore: 210),
    FDLegendChallenge(id: "legend_sorcier", name: "Le Sorcier", era: "Années 1990", nationality: "Cameroun", position: .attaquant, style: .createur, personality: .charismatique,
                      archetype: "Dribbles impossibles et sourire ravageur, l'idole de tout un continent.", unlockCost: 78, targetScore: 215),
    FDLegendChallenge(id: "legend_general", name: "Le Général", era: "Années 1980", nationality: "Argentine", position: .milieu, style: .leader, personality: .provocateur,
                      archetype: "Il gueulait sur tout le monde, et tout le monde jouait mieux.", unlockCost: 80, targetScore: 220),
    FDLegendChallenge(id: "legend_pieuvre", name: "La Pieuvre", era: "Années 2000", nationality: "Espagne", position: .gardien, style: .recuperateur, personality: .discipline,
                      archetype: "Des bras partout, une surface interdite pendant douze saisons.", unlockCost: 82, targetScore: 205),
    FDLegendChallenge(id: "legend_flecha", name: "La Flecha", era: "Années 2010", nationality: "Colombie", position: .attaquant, style: .rapide, personality: .ambitieux,
                      archetype: "Le contre-attaquant absolu, imprenable sur trente mètres.", unlockCost: 86, targetScore: 230),
    FDLegendChallenge(id: "legend_horloger", name: "L'Horloger", era: "Années 2010", nationality: "Croatie", position: .milieu, style: .createur, personality: .reserve,
                      archetype: "Chaque passe au millimètre, chaque déplacement à la seconde près.", unlockCost: 90, targetScore: 235),
    FDLegendChallenge(id: "legend_lion_atlas", name: "Le Lion de l'Atlas", era: "Années 1990", nationality: "Maroc", position: .milieu, style: .puissant, personality: .ambitieux,
                      archetype: "Le premier à faire trembler l'Europe au nom de tout un pays.", unlockCost: 94, targetScore: 240),
    FDLegendChallenge(id: "legend_kaiser", name: "Kaiser du Milieu", era: "Années 2010", nationality: "Allemagne", position: .milieu, style: .leader, personality: .travailleur,
                      archetype: "Le patron du milieu, celui qui fait tourner toute une génération dorée.", unlockCost: 98, targetScore: 245),
    FDLegendChallenge(id: "legend_taureau", name: "Le Taureau", era: "Années 1990", nationality: "Uruguay", position: .attaquant, style: .puissant, personality: .provocateur,
                      archetype: "Un avant-centre qu'aucun défenseur ne voulait affronter deux fois.", unlockCost: 102, targetScore: 250),
    FDLegendChallenge(id: "legend_samourai", name: "Le Samouraï", era: "Années 2000", nationality: "Japon", position: .milieu, style: .technicien, personality: .discipline,
                      archetype: "Une rigueur absolue au service d'une technique irréprochable.", unlockCost: 106, targetScore: 245),
    FDLegendChallenge(id: "legend_aigle_carthage", name: "L'Aigle de Carthage", era: "Années 2000", nationality: "Tunisie", position: .attaquant, style: .finisseur, personality: .ambitieux,
                      archetype: "Il a marqué dans tous les stades du continent, et ailleurs aussi.", unlockCost: 110, targetScore: 255),
    FDLegendChallenge(id: "legend_viking", name: "Le Viking", era: "Années 2010", nationality: "Suède", position: .attaquant, style: .puissant, personality: .provocateur,
                      archetype: "Deux mètres d'arrogance assumée et de gestes impossibles.", unlockCost: 115, targetScore: 265),
    FDLegendChallenge(id: "legend_panthere", name: "La Panthère", era: "Années 1990", nationality: "Brésil", position: .attaquant, style: .finisseur, personality: .ambitieux,
                      archetype: "Vitesse féline et sens du but hors normes, la terreur des défenses.", unlockCost: 120, targetScore: 270),

    // ================= Palier 3 — 16 défis exigeants (150–230 pièces) =================
    FDLegendChallenge(id: "legend_divin", name: "Il Divin", era: "Années 1990", nationality: "Italie", position: .attaquant, style: .technicien, personality: .charismatique,
                      archetype: "Élégance italienne, un jeu de tête et une frappe qui ont marqué une génération.", unlockCost: 150, targetScore: 300),
    FDLegendChallenge(id: "legend_pistolero", name: "El Pistolero", era: "Années 2010", nationality: "Uruguay", position: .attaquant, style: .finisseur, personality: .provocateur,
                      archetype: "Un tempérament de feu et une efficacité clinique, saison après saison.", unlockCost: 158, targetScore: 310),
    FDLegendChallenge(id: "legend_pharaon", name: "Le Pharaon", era: "Années 2010", nationality: "Égypte", position: .attaquant, style: .rapide, personality: .travailleur,
                      archetype: "Parti de rien, devenu le visage du football de tout un continent.", unlockCost: 165, targetScore: 320),
    FDLegendChallenge(id: "legend_architecte", name: "L'Architecte", era: "Années 2000", nationality: "Espagne", position: .milieu, style: .createur, personality: .reserve,
                      archetype: "Il n'a jamais couru vite, il a simplement toujours su où aller.", unlockCost: 170, targetScore: 315),
    FDLegendChallenge(id: "legend_muraille_verte", name: "La Muraille Verte", era: "Années 2010", nationality: "Sénégal", position: .defenseur, style: .puissant, personality: .discipline,
                      archetype: "Le défenseur le plus redouté de sa décennie, sur deux continents.", unlockCost: 175, targetScore: 290),
    FDLegendChallenge(id: "legend_condor", name: "El Condor", era: "Années 1980", nationality: "Argentine", position: .attaquant, style: .createur, personality: .irregulier,
                      archetype: "Capable du geste du siècle un dimanche, invisible le suivant.", unlockCost: 180, targetScore: 330),
    FDLegendChallenge(id: "legend_rey", name: "El Rey", era: "Années 1980", nationality: "Argentine", position: .milieu, style: .technicien, personality: .irregulier,
                      archetype: "Génie imprévisible, capable de gagner un match à lui seul.", unlockCost: 188, targetScore: 340),
    FDLegendChallenge(id: "legend_iceman", name: "The Iceman", era: "Années 2020", nationality: "Norvège", position: .attaquant, style: .finisseur, personality: .discipline,
                      archetype: "Sang-froid absolu devant le but, une machine à statistiques.", unlockCost: 195, targetScore: 350),
    FDLegendChallenge(id: "legend_faucon", name: "Le Faucon", era: "Années 2000", nationality: "Turquie", position: .attaquant, style: .rapide, personality: .charismatique,
                      archetype: "Il fondait sur les défenses comme un rapace, tout un stade debout.", unlockCost: 200, targetScore: 345),
    FDLegendChallenge(id: "legend_dragon", name: "Le Dragon", era: "Années 2010", nationality: "Corée du Sud", position: .attaquant, style: .rapide, personality: .travailleur,
                      archetype: "Le premier de son pays à s'imposer durablement au sommet européen.", unlockCost: 205, targetScore: 340),
    FDLegendChallenge(id: "legend_gardien_fou", name: "Le Gardien Fou", era: "Années 1990", nationality: "Colombie", position: .gardien, style: .createur, personality: .provocateur,
                      archetype: "Il montait marquer des coups francs. Et ça marchait.", unlockCost: 210, targetScore: 300),
    FDLegendChallenge(id: "legend_scorpion", name: "Le Scorpion", era: "Années 2000", nationality: "Mexique", position: .attaquant, style: .technicien, personality: .charismatique,
                      archetype: "Des gestes que personne n'avait tentés avant lui.", unlockCost: 215, targetScore: 355),
    FDLegendChallenge(id: "legend_ours", name: "L'Ours des Balkans", era: "Années 1990", nationality: "Croatie", position: .attaquant, style: .finisseur, personality: .ambitieux,
                      archetype: "Un buteur né qui a porté un petit pays au sommet du monde.", unlockCost: 220, targetScore: 360),
    FDLegendChallenge(id: "legend_libero_total", name: "Le Libéro Total", era: "Années 1970", nationality: "Pays-Bas", position: .defenseur, style: .createur, personality: .charismatique,
                      archetype: "Défenseur, milieu, attaquant — parfois dans la même action.", unlockCost: 225, targetScore: 330),
    FDLegendChallenge(id: "legend_eternel", name: "L'Éternel", era: "Années 2010", nationality: "Italie", position: .gardien, style: .leader, personality: .discipline,
                      archetype: "Vingt-deux saisons au plus haut niveau, sans jamais baisser d'un ton.", unlockCost: 228, targetScore: 340),
    FDLegendChallenge(id: "legend_rei_do_gol", name: "O Rei do Gol", era: "Années 1960", nationality: "Brésil", position: .attaquant, style: .finisseur, personality: .ambitieux,
                      archetype: "Le buteur des buteurs, une légende que les grands-parents racontent encore.", unlockCost: 230, targetScore: 380),

    // ================= Palier 4 — 10 défis d'élite (300–420 pièces) =================
    FDLegendChallenge(id: "legend_ombre_dor", name: "L'Ombre d'Or", era: "Années 2000", nationality: "Portugal", position: .attaquant, style: .technicien, personality: .charismatique,
                      archetype: "Une obsession de la perfection qui a redéfini le métier d'attaquant.", unlockCost: 300, targetScore: 430),
    FDLegendChallenge(id: "legend_lutin", name: "Le Lutin", era: "Années 2010", nationality: "Argentine", position: .attaquant, style: .createur, personality: .reserve,
                      archetype: "Le plus petit sur le terrain, et pourtant intouchable pendant quinze ans.", unlockCost: 315, targetScore: 450),
    FDLegendChallenge(id: "legend_empereur", name: "L'Empereur", era: "Années 1970", nationality: "Allemagne", position: .defenseur, style: .leader, personality: .charismatique,
                      archetype: "Il a inventé un poste, puis gagné tout ce qu'il y avait à gagner dessus.", unlockCost: 330, targetScore: 400),
    FDLegendChallenge(id: "legend_hollandais", name: "Le Hollandais Volant", era: "Années 1970", nationality: "Pays-Bas", position: .attaquant, style: .createur, personality: .provocateur,
                      archetype: "Le football total incarné dans un seul joueur, insupportable et génial.", unlockCost: 345, targetScore: 440),
    FDLegendChallenge(id: "legend_phenomene", name: "Le Phénomène", era: "Années 1990", nationality: "Brésil", position: .attaquant, style: .rapide, personality: .ambitieux,
                      archetype: "Trois saisons d'un niveau que le football n'avait jamais vu — puis les genoux.", unlockCost: 360, targetScore: 460),
    FDLegendChallenge(id: "legend_general_dor", name: "Le Général d'Or", era: "Années 1990", nationality: "France", position: .milieu, style: .leader, personality: .charismatique,
                      archetype: "Deux coups de tête, un pays entier dans la rue, une carrière de patron.", unlockCost: 375, targetScore: 470),
    FDLegendChallenge(id: "legend_perle_noire", name: "La Perle Noire", era: "Années 1960", nationality: "Brésil", position: .attaquant, style: .technicien, personality: .ambitieux,
                      archetype: "Trois titres mondiaux et plus de mille buts. La référence absolue.", unlockCost: 390, targetScore: 500),
    FDLegendChallenge(id: "legend_main_dieu", name: "La Main du Destin", era: "Années 1980", nationality: "Argentine", position: .attaquant, style: .createur, personality: .irregulier,
                      archetype: "Il a gagné une Coupe du monde presque seul, dans un tourbillon de génie et de chaos.", unlockCost: 400, targetScore: 510),
    FDLegendChallenge(id: "legend_machine", name: "La Machine", era: "Années 2010", nationality: "Portugal", position: .attaquant, style: .puissant, personality: .ambitieux,
                      archetype: "Vingt ans au sommet par la seule force du travail et de l'obsession.", unlockCost: 410, targetScore: 530),
    FDLegendChallenge(id: "legend_intouchable", name: "L'Intouchable", era: "Toutes époques", nationality: "France", position: .attaquant, style: .finisseur, personality: .ambitieux,
                      archetype: "Le sommet du jeu. Personne n'a jamais fait mieux, et personne ne devrait pouvoir.", unlockCost: 420, targetScore: 580),
]
