# Football Destiny — iOS (SwiftUI)

App iOS native (Swift 5 / SwiftUI, iOS 15+) : simulateur de carrière de
footballeur, jouable immédiatement sans inscription ni compte. Projet
autonome, séparé de FCS Manager.

## Ouvrir le projet

1. Cloner ce dépôt.
2. Ouvrir **`FootballDestiny.xcodeproj`** dans Xcode (pas de workspace, pas de
   CocoaPods — aucune dépendance externe).
3. Dans l'onglet **Signing & Capabilities** du target `FootballDestiny`,
   sélectionner ton équipe de développement (Team) pour la signature
   automatique.
4. Choisir un simulateur iPhone, lancer avec ▶️ (⌘R).

> **Je n'ai pas pu compiler ce projet moi-même** — l'environnement dans lequel
> je travaille est un conteneur Linux sans Xcode. J'ai construit le fichier
> `.xcodeproj` à la main et vérifié par script sa cohérence (UUID uniques,
> parenthèses/accolades équilibrées, chaque fichier référencé existe bien sur
> disque), mais la toute première compilation réelle doit se faire dans ton
> Xcode. Remonte-moi la moindre erreur, je corrige immédiatement.

## Contenu

- `FootballDestinyApp.swift` — point d'entrée SwiftUI (`@main`).
- `FDModels.swift` — types de données (joueur, club, attributs) + `Codable`.
- `FDClubDatabase.swift` — 355 clubs réels (noms/villes réels, aucun écusson,
  maillot ou nom de compétition officiel), 6 confédérations, statistiques de
  jeu dérivées procéduralement (facile à corriger/étendre).
- `FDScenes.swift` — contenu narratif (scènes, choix, effets).
- `FDGameEngine.swift` — logique de jeu complète (création du joueur,
  simulation de matchs, saisons, sauvegarde locale via `UserDefaults`).
- `FDMainMenuView.swift`, `FDCareerCreationView.swift`, `FDGameShellView.swift`,
  `FDRootView.swift` — l'interface (menu, création en 3 étapes, écran de jeu à
  5 onglets).

## Avant de publier

Ce projet est configuré pour tourner et se signer facilement en local
(signature automatique, pas d'identifiant d'équipe figé). Avant toute
distribution (TestFlight / App Store), il faudra :

- Choisir un vrai **bundle identifier** (actuellement `com.footballdestiny.ios`,
  à remplacer dans Signing & Capabilities).
- Créer l'app correspondante sur **App Store Connect**.
- Ajouter une vraie icône d'app dans `Assets.xcassets/AppIcon.appiconset`
  (actuellement vide).
- Compléter `codemagic.yaml` avec la config de signature + de publication
  (laissé volontairement minimal pour l'instant, pour qu'aucun build ne parte
  par accident vers TestFlight).
