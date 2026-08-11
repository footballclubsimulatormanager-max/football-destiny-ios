import Foundation

// Handwritten narrative scenes, ported 1:1 from the web prototype's content.
let FDScenes: [FDSceneDef] = [
    FDSceneDef(
        id: "academie_arrivee", category: "Académie", minAge: 15, maxAge: 15, statuses: [.u16], once: true,
        location: "Centre de formation", character: "Entraîneur des jeunes",
        text: "Premier jour au centre de formation. L'entraîneur te regarde t'échauffer avec les autres jeunes. « On verra ce que tu as dans le ventre. »",
        choices: [
            FDChoice(label: "Se donner à fond dès l'échauffement", hint: "+Détermination +Relation coach",
                      effects: [FDEffect(attr: .determination, delta: 2), FDEffect(rel: "coach", delta: 4), FDEffect(cond: "fatigue", delta: 6)]),
            FDChoice(label: "Observer et rester discret", hint: "+Sang-froid",
                      effects: [FDEffect(attr: .sangfroid, delta: 2), FDEffect(cond: "confiance", delta: -1)]),
        ]),
    FDSceneDef(
        id: "famille_soutien", category: "Famille", minAge: 15, maxAge: 17, statuses: [.u16, .u18],
        location: "Maison familiale", character: "Ta mère",
        text: "« Tu rentres tard tous les soirs pour tes entraînements. Tu es sûr que c'est ce que tu veux vraiment faire de ta vie ? »",
        choices: [
            FDChoice(label: "« C'est mon rêve, je vais y arriver »", hint: "+Détermination +Famille",
                      effects: [FDEffect(attr: .determination, delta: 2), FDEffect(rel: "famille", delta: 5), FDEffect(cond: "moral", delta: 3)]),
            FDChoice(label: "Rassurer sans trop en dire", hint: "+Famille",
                      effects: [FDEffect(rel: "famille", delta: 2)]),
            FDChoice(label: "S'énerver et sortir", hint: "-Famille -Moral",
                      effects: [FDEffect(rel: "famille", delta: -6), FDEffect(cond: "moral", delta: -4)]),
        ]),
    FDSceneDef(
        id: "premier_essai", category: "Essais", minAge: 15, maxAge: 16, statuses: [.u16], once: true,
        location: "Terrain d'entraînement", character: "Recruteur",
        text: "Un recruteur observe la séance depuis le bord du terrain, carnet à la main. Ta prochaine action peut faire la différence.",
        choices: [
            FDChoice(label: "Tenter le geste technique risqué", hint: "Risque/récompense sur ta technique",
                      effects: [FDEffect(attr: .dribble, delta: Int.random(in: 1...3)), FDEffect(cond: "confiance", delta: 4), FDEffect(rel: "coach", delta: -1)]),
            FDChoice(label: "Jouer simple et efficace", hint: "+Placement +Relation coach",
                      effects: [FDEffect(attr: .placement, delta: 2), FDEffect(rel: "coach", delta: 3)]),
        ]),
    FDSceneDef(
        id: "vestiaire_ambiance", category: "Vestiaire", minAge: 15, maxAge: 34,
        location: "Vestiaire", character: "Capitaine de l'équipe",
        text: "Dans le vestiaire, un coéquipier plus âgé te charrie devant tout le monde sur ta première touche de balle du match.",
        choices: [
            FDChoice(label: "Rire avec lui, jouer le jeu", hint: "+Vestiaire",
                      effects: [FDEffect(rel: "vestiaire", delta: 5), FDEffect(cond: "moral", delta: 2)]),
            FDChoice(label: "Répondre avec assurance", hint: "+Leadership, risque tension",
                      effects: [FDEffect(attr: .leadership, delta: 2), FDEffect(rel: "vestiaire", delta: -2), FDEffect(rel: "capitaine", delta: 2)]),
            FDChoice(label: "Ignorer et se concentrer", hint: "+Sang-froid",
                      effects: [FDEffect(attr: .sangfroid, delta: 1)]),
        ]),
    FDSceneDef(
        id: "entrainement_extra", category: "Entraînement", minAge: 15, maxAge: 40,
        location: "Terrain annexe", character: "Préparateur physique",
        text: "Le préparateur physique te propose une séance supplémentaire après l'entraînement collectif, sur ton temps libre.",
        choices: [
            FDChoice(label: "Accepter et travailler la finition", hint: "+Tir, +Fatigue",
                      effects: [FDEffect(attr: .tir, delta: 2), FDEffect(cond: "fatigue", delta: 10)]),
            FDChoice(label: "Accepter et travailler le physique", hint: "+Physique, +Fatigue",
                      effects: [FDEffect(attr: .force, delta: 1), FDEffect(attr: .endurance, delta: 1), FDEffect(cond: "fatigue", delta: 10)]),
            FDChoice(label: "Décliner, se reposer", hint: "+Forme -Fatigue",
                      effects: [FDEffect(cond: "fatigue", delta: -8), FDEffect(cond: "forme", delta: 3)]),
        ]),
    FDSceneDef(
        id: "reseaux_sociaux", category: "Presse", minAge: 16, maxAge: 40,
        location: "Téléphone", character: "—",
        text: "Une courte vidéo de toi devient virale sur les réseaux après le dernier match. Les commentaires sont partagés.",
        choices: [
            FDChoice(label: "Publier un message humble", hint: "+Popularité +Média",
                      effects: [FDEffect(rel: "media", delta: 4), FDEffect(cond: "reputation", delta: 2)]),
            FDChoice(label: "Ignorer complètement", hint: "Neutre",
                      effects: [FDEffect(cond: "confiance", delta: 1)]),
            FDChoice(label: "Répondre à un hater", hint: "-Média -Moral",
                      effects: [FDEffect(rel: "media", delta: -5), FDEffect(cond: "moral", delta: -2)]),
        ]),
    FDSceneDef(
        id: "blessure_legere", category: "Blessure", minAge: 15, maxAge: 40,
        location: "Infirmerie du club", character: "Médecin du club",
        text: "Tu ressens une gêne musculaire après l'entraînement. Le médecin te propose deux options.",
        choices: [
            FDChoice(label: "Repos complet une semaine", hint: "+Santé -Temps de jeu",
                      effects: [FDEffect(cond: "fatigue", delta: -15), FDEffect(cond: "forme", delta: -3)]),
            FDChoice(label: "Jouer avec un strapping", hint: "Risque d'aggravation",
                      effects: [FDEffect(cond: "fatigue", delta: 5), FDEffect(attr: .determination, delta: 1)],
                      riskChance: 0.18,
                      riskEffects: [FDEffect(cond: "forme", delta: -15), FDEffect(cond: "moral", delta: -8)],
                      riskText: "La blessure s'aggrave. Tu es indisponible plusieurs semaines."),
        ]),
    FDSceneDef(
        id: "agent_contact", category: "Agent", minAge: 16, maxAge: 40,
        location: "Café en ville", character: "Agent de joueurs",
        text: "Un agent t'aborde après l'entraînement et te propose de représenter tes intérêts pour la suite de ta carrière.",
        choices: [
            FDChoice(label: "Signer avec lui", hint: "+Relation agent, aide négociations",
                      effects: [FDEffect(rel: "agent", delta: 15), FDEffect(cond: "confiance", delta: 3)]),
            FDChoice(label: "Rester prudent, sans engagement", hint: "Neutre", effects: []),
        ]),
    FDSceneDef(
        id: "presse_conference", category: "Presse", minAge: 18, maxAge: 40,
        location: "Salle de presse", character: "Journaliste",
        text: "« Après votre belle performance, on dit que de grands clubs s'intéressent à vous. Un commentaire ? »",
        choices: [
            FDChoice(label: "Rester humble, parler collectif", hint: "+Média +Vestiaire",
                      effects: [FDEffect(rel: "media", delta: 4), FDEffect(rel: "vestiaire", delta: 2)]),
            FDChoice(label: "Affirmer ses ambitions", hint: "+Réputation, -Relation club",
                      effects: [FDEffect(cond: "reputation", delta: 5), FDEffect(rel: "president", delta: -4)]),
        ]),
    FDSceneDef(
        id: "sponsor_offre", category: "Sponsor", minAge: 17, maxAge: 40,
        location: "Bureaux d'une marque", character: "Représentant marque sportive",
        text: "Une marque d'équipement te propose un petit contrat de sponsoring en échange de posts réguliers.",
        choices: [
            FDChoice(label: "Accepter", hint: "+Argent +Popularité, +Pression",
                      effects: [FDEffect(money: 4000), FDEffect(cond: "reputation", delta: 2), FDEffect(cond: "forme", delta: -1)]),
            FDChoice(label: "Refuser pour rester concentré", hint: "+Sang-froid",
                      effects: [FDEffect(attr: .sangfroid, delta: 1)]),
        ]),
    FDSceneDef(
        id: "contrat_pro_offre", category: "Contrat", minAge: 15, maxAge: 17, statuses: [.u18], once: true,
        location: "Bureau du directeur sportif", character: "Directeur sportif",
        text: "« Tes performances en U18 ont convaincu le club. On veut te proposer ton premier contrat professionnel. »",
        choices: [
            FDChoice(label: "Signer immédiatement", hint: "Statut → Pro",
                      effects: [FDEffect(cond: "confiance", delta: 8), FDEffect(rel: "president", delta: 5)],
                      setStatus: .pro, setContractSalary: 3200, setContractYears: 2),
            FDChoice(label: "Négocier via l'agent d'abord", hint: "Nécessite un agent",
                      effects: [FDEffect(rel: "agent", delta: 5)],
                      setStatus: .pro, setContractSalary: 4600, setContractYears: 2),
        ]),
    FDSceneDef(
        id: "couple_rencontre", category: "Couple", minAge: 18, maxAge: 40, once: true,
        location: "Soirée d'équipe", character: "—",
        text: "Lors d'une sortie organisée par le club, tu fais une rencontre qui pourrait devenir importante pour toi.",
        choices: [
            FDChoice(label: "Prendre le temps de discuter", hint: "+Partenaire +Moral",
                      effects: [FDEffect(rel: "partenaire", delta: 10), FDEffect(cond: "moral", delta: 4)]),
            FDChoice(label: "Rester concentré sur le foot", hint: "Neutre",
                      effects: [FDEffect(attr: .determination, delta: 1)]),
        ]),
    FDSceneDef(
        id: "logement_choix", category: "Logement", minAge: 18, maxAge: 24, once: true,
        location: "Agence immobilière", character: "Agent immobilier",
        text: "Il est temps de quitter le foyer du club. Où souhaites-tu t'installer ?",
        choices: [
            FDChoice(label: "Appartement simple près du centre d'entraînement", hint: "Économique",
                      effects: [FDEffect(money: -1500), FDEffect(cond: "fatigue", delta: -3)]),
            FDChoice(label: "Appartement en centre-ville", hint: "Plus cher, plus de vie sociale",
                      effects: [FDEffect(money: -4000), FDEffect(cond: "moral", delta: 4)]),
        ]),
    FDSceneDef(
        id: "investissement", category: "Argent", minAge: 20, maxAge: 40,
        location: "Rendez-vous conseiller financier", character: "Conseiller financier",
        text: "Ton conseiller te propose de placer une partie de tes revenus dans un investissement à moyen terme.",
        choices: [
            FDChoice(label: "Investir prudemment", hint: "Coût maintenant, gain plus tard",
                      effects: [FDEffect(money: -5000)],
                      delayedWeeks: 12, delayedEffects: [FDEffect(money: 7500)], delayedText: "Ton investissement porte ses fruits."),
            FDChoice(label: "Ne pas investir", hint: "Neutre", effects: []),
        ]),
    FDSceneDef(
        id: "crise_forme", category: "Crise", minAge: 16, maxAge: 40,
        location: "Après l'entraînement", character: "Entraîneur",
        text: "« Tu traverses une période compliquée. On sent que la tête n'y est pas complètement. » L'entraîneur t'observe, inquiet.",
        choices: [
            FDChoice(label: "Demander de l'aide au psychologue du club", hint: "+Moral +Forme",
                      effects: [FDEffect(cond: "moral", delta: 8), FDEffect(cond: "forme", delta: 6)]),
            FDChoice(label: "Assurer que tout va bien", hint: "Risque de rechute",
                      effects: [FDEffect(rel: "coach", delta: -2)]),
        ],
        condition: { p in p.cond.forme < 40 }),
    FDSceneDef(
        id: "selection_convocation_jeune", category: "Sélection", minAge: 16, maxAge: 19, once: true,
        location: "Courrier officiel", character: "Fédération nationale",
        text: "Une lettre officielle arrive : tu es convoqué pour la première fois avec une sélection nationale de jeunes !",
        choices: [
            FDChoice(label: "Répondre présent avec fierté", hint: "+Réputation +Détermination",
                      effects: [FDEffect(cond: "reputation", delta: 8), FDEffect(attr: .determination, delta: 2)]),
        ],
        condition: { p in p.cond.reputation >= 15 }),
    FDSceneDef(
        id: "transfert_interet", category: "Transfert", minAge: 19, maxAge: 33,
        location: "Rumeur de marché", character: "Agent",
        text: "Ton agent t'appelle : un club d'un plus grand championnat s'est renseigné sur ta situation contractuelle.",
        choices: [
            FDChoice(label: "Se dire prêt à partir", hint: "+Ambition, -Relation club actuel",
                      effects: [FDEffect(rel: "president", delta: -5), FDEffect(cond: "confiance", delta: 5)]),
            FDChoice(label: "Rester loyal pour l'instant", hint: "+Relation club",
                      effects: [FDEffect(rel: "president", delta: 5), FDEffect(rel: "vestiaire", delta: 2)]),
        ],
        condition: { p in p.cond.reputation >= 35 }),
    FDSceneDef(
        id: "trophee_saison", category: "Trophée", minAge: 18, maxAge: 40,
        location: "Cérémonie du club", character: "Président du club",
        text: "Le club célèbre une belle saison collective. Ton nom est cité parmi les artisans de la réussite.",
        choices: [
            FDChoice(label: "Savourer avec le groupe", hint: "+Vestiaire +Popularité",
                      effects: [FDEffect(rel: "vestiaire", delta: 5), FDEffect(cond: "reputation", delta: 4)]),
        ],
        condition: { p in p.cond.forme >= 70 }),
    FDSceneDef(
        id: "retraite_reflexion", category: "Retraite", minAge: 34, maxAge: 43,
        location: "Vestiaire, après l'entraînement", character: "Toi-même",
        text: "Le corps ne répond plus tout à fait comme avant. L'idée de l'après-carrière commence sérieusement à te traverser l'esprit. Tu peux prendre ta retraite à tout moment depuis l'onglet Options.",
        choices: [
            FDChoice(label: "Prolonger tant que le corps suit", hint: "+Détermination -Forme",
                      effects: [FDEffect(attr: .determination, delta: 1), FDEffect(cond: "forme", delta: -2)]),
            FDChoice(label: "Commencer à préparer la reconversion", hint: "+Sérénité",
                      effects: [FDEffect(cond: "moral", delta: 5)]),
        ]),
    FDSceneDef(
        id: "vestiaire_capitanat", category: "Vestiaire", minAge: 20, maxAge: 34, once: true,
        location: "Vestiaire, avant un match clé", character: "Coéquipiers",
        text: "Le groupe traverse une période de doute. Certains regardent vers toi pour prendre la parole avant d'entrer sur le terrain.",
        choices: [
            FDChoice(label: "Prendre la parole et galvaniser le groupe", hint: "+Leadership +Vestiaire",
                      effects: [FDEffect(attr: .leadership, delta: 4), FDEffect(rel: "vestiaire", delta: 6), FDEffect(rel: "capitaine", delta: 4)],
                      trait: .leaderNe),
            FDChoice(label: "Rester silencieux et laisser faire", hint: "+Sang-froid, -Confiance",
                      effects: [FDEffect(attr: .sangfroid, delta: 3), FDEffect(cond: "confiance", delta: -2)],
                      trait: .joueurEnRetrait),
        ],
        condition: { p in p.cond.reputation >= 20 }),
    FDSceneDef(
        id: "transfert_choix_mercenaire", category: "Transfert", minAge: 22, maxAge: 33, once: true,
        location: "Bureau de l'agent", character: "Agent",
        text: "Deux offres sur la table : un club moins huppé prêt à payer le double de ton salaire actuel, ou une place mieux établie pour moins d'argent.",
        choices: [
            FDChoice(label: "Suivre l'argent, sans hésiter", hint: "+Argent, -Réputation",
                      effects: [FDEffect(money: 40000), FDEffect(cond: "reputation", delta: -3)],
                      trait: .mercenaire),
            FDChoice(label: "Privilégier le projet sportif", hint: "+Réputation",
                      effects: [FDEffect(cond: "reputation", delta: 5)]),
        ],
        condition: { p in p.cond.reputation >= 30 }),
    FDSceneDef(
        id: "vestiaire_show", category: "Presse", minAge: 18, maxAge: 40, once: true,
        location: "Mixed zone, après le match", character: "Caméras de télévision",
        text: "Les caméras t'attendent à la sortie du vestiaire après une performance remarquée. De quoi marquer les esprits, dans un sens ou dans l'autre.",
        choices: [
            FDChoice(label: "Un numéro pour le public, célébration mémorable", hint: "+Fans +Média",
                      effects: [FDEffect(rel: "fans", delta: 6), FDEffect(rel: "media", delta: 4)],
                      trait: .showman),
            FDChoice(label: "Rester sobre, laisser parler le jeu", hint: "+Relation coach",
                      effects: [FDEffect(rel: "coach", delta: 3)]),
        ],
        condition: { p in p.cond.reputation >= 25 }),
    FDSceneDef(
        id: "moment_decisif_penalty", category: "Moment décisif", minAge: 18, maxAge: 40,
        location: "Finale de Coupe Nationale", character: "90e minute, 1-1",
        text: "Penalty décisif en finale. Le stade retient son souffle, le ballon est posé sur le point.",
        choices: [
            FDChoice(label: "Tir placé, assurer l'essentiel", hint: "Sûr",
                      effects: [FDEffect(cond: "confiance", delta: 3)],
                      riskChance: 0.15,
                      riskEffects: [FDEffect(cond: "moral", delta: -6), FDEffect(cond: "confiance", delta: -4)],
                      riskText: "Le gardien détourne le tir du bout des doigts."),
            FDChoice(label: "Panenka, sang-froid total", hint: "Légendaire",
                      effects: [FDEffect(attr: .sangfroid, delta: 4), FDEffect(cond: "reputation", delta: 10)],
                      riskChance: 0.4,
                      riskEffects: [FDEffect(cond: "moral", delta: -10), FDEffect(cond: "reputation", delta: -6)],
                      riskText: "Le Panenka est lu par le gardien. Silence de mort dans le stade."),
        ],
        condition: { p in p.cond.reputation >= 40 }),
    FDSceneDef(
        id: "moment_decisif_contre", category: "Moment décisif", minAge: 18, maxAge: 40,
        location: "Contre-attaque, 88e minute", character: "1-1, un coéquipier démarqué",
        text: "Contre à deux contre un à la 88e d'une finale. Tu portes le ballon, un coéquipier hurle sur ta gauche, le défenseur recule.",
        choices: [
            FDChoice(label: "Y aller seul et frapper", hint: "Égo",
                      effects: [FDEffect(attr: .tir, delta: 2), FDEffect(cond: "confiance", delta: 3)],
                      riskChance: 0.35,
                      riskEffects: [FDEffect(rel: "vestiaire", delta: -4)],
                      riskText: "Le tir passe au-dessus. Le coéquipier démarqué n'a pas caché son agacement."),
            FDChoice(label: "Servir le coéquipier au bon moment", hint: "Collectif",
                      effects: [FDEffect(attr: .vision, delta: 2), FDEffect(rel: "vestiaire", delta: 5)]),
        ],
        condition: { p in p.cond.reputation >= 35 }),
]

// Generic filler pools: (title, text, effects)
let FDGenericTraining: [(String, String, [FDEffect])] = [
    ("Séance de tirs au but", "Le coach organise un concours de finition avant l'entraînement collectif.", [FDEffect(attr: .tir, delta: 2), FDEffect(cond: "fatigue", delta: 7)]),
    ("Travail tactique", "Longue séance vidéo puis mise en application sur le terrain.", [FDEffect(attr: .vision, delta: 2), FDEffect(cond: "fatigue", delta: 5)]),
    ("Renforcement musculaire", "Séance en salle avec le préparateur physique.", [FDEffect(attr: .force, delta: 2), FDEffect(cond: "fatigue", delta: 9)]),
    ("Travail de vitesse", "Sprints et changements de direction sur le terrain synthétique.", [FDEffect(attr: .vitesse, delta: 2), FDEffect(cond: "fatigue", delta: 8)]),
    ("Ateliers techniques", "Circuit de contrôle, passe et dribble en conditions rapprochées.", [FDEffect(attr: .control, delta: 2), FDEffect(cond: "fatigue", delta: 6)]),
    ("Opposition en petit groupe", "Match à effectif réduit très intense entre coéquipiers.", [FDEffect(attr: .dribble, delta: 1), FDEffect(rel: "vestiaire", delta: 2), FDEffect(cond: "fatigue", delta: 9)]),
]
let FDGenericLife: [(String, String, [FDEffect])] = [
    ("Soirée entre coéquipiers", "Le groupe t'invite à décompresser après une semaine chargée.", [FDEffect(rel: "vestiaire", delta: 4), FDEffect(cond: "moral", delta: 3), FDEffect(cond: "fatigue", delta: 3)]),
    ("Appel de la famille", "Tes proches prennent des nouvelles et t'encouragent.", [FDEffect(rel: "famille", delta: 3), FDEffect(cond: "moral", delta: 3)]),
    ("Jour de repos", "Une journée sans obligation, à toi de voir comment la passer.", [FDEffect(cond: "fatigue", delta: -10), FDEffect(cond: "forme", delta: 2)]),
    ("Séance photo du club", "Le club organise une séance promotionnelle avec les joueurs.", [FDEffect(cond: "reputation", delta: 1), FDEffect(cond: "fatigue", delta: 2)]),
    ("Discussion avec un vétéran", "Un joueur expérimenté du vestiaire te donne quelques conseils.", [FDEffect(attr: .sangfroid, delta: 1), FDEffect(rel: "vestiaire", delta: 2)]),
    ("Fan zone", "Rencontre avec des jeunes supporters après l'entraînement.", [FDEffect(cond: "reputation", delta: 2), FDEffect(rel: "fans", delta: 4)]),
]
let FDGenericPress: [(String, String, [FDEffect])] = [
    ("Interview d'après-match", "Un journaliste te demande ton ressenti sur la rencontre.", [FDEffect(rel: "media", delta: 2)]),
    ("Émission sportive locale", "Tu es invité à commenter l'actualité du club.", [FDEffect(cond: "reputation", delta: 2)]),
    ("Rumeur de vestiaire", "Un article évoque des tensions internes, sans te citer directement.", [FDEffect(cond: "moral", delta: -1)]),
]
