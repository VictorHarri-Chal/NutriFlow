# Design — Refonte circulaire du widget Calories/Macros

**Date**: 2026-07-07
**Statut**: En attente de revue utilisateur

## Contexte

La section "CALORIES" de la page calendrier (`app/views/calendars/_daily_panel.html.erb`) affiche
actuellement calories, protéines, glucides, lipides et sucres sous forme de barres de progression
horizontales. L'utilisateur souhaite remplacer ce design par des ronds de progression (SVG,
`stroke-dasharray`), sur le modèle du rond d'hydratation déjà existant (`_water_widget.html.erb`),
et ajouter l'affichage de trois nouvelles valeurs actuellement absentes de cette page : fibres,
graisses saturées et sel.

### État actuel (constats de l'exploration du code)

- Les barres de `_daily_panel.html.erb` n'utilisent **pas** la classe `.progress-track` — elles
  inlinent des classes utilitaires directement. `.progress-track` et les partials
  `_daily_objectives.html.erb` / `_calories_objective.html.erb` / etc. sont du code mort, non
  rendu nulle part. Ils restent inchangés (hors scope).
- Le rond d'hydratation (`_water_widget.html.erb`) est un SVG entièrement codé en dur dans l'ERB
  (rayon, `stroke-width`, couleurs hex en dur `#22C55E`/`#3B82F6`/`#F59E0B`/`#EF4444`/`#3F3F46`),
  sans composant ni partial réutilisable.
- `fiber`, `saturated_fat`, `salt` existent en base sur `foods` et sont déjà agrégés sur `Recipe`
  (`total_fiber`, `total_saturated_fat`, `total_salt`), mais **pas** sur `DayFood`, et
  `CalendarDataLoader` ne les additionne pas au niveau du jour.
- `Profile` n'a pas d'objectif journalier pour fibres/sel/graisses saturées (seulement
  calories/protéines/glucides/lipides).
- Tokens couleur macro existants (`tailwind.config.js`) : `macro-calories`, `macro-proteins`,
  `macro-carbs`, `macro-fats`, `macro-sugars`. Pas de token pour fibres/sel/graisses saturées.

## Objectifs

1. Remplacer les barres horizontales de la section CALORIES par un tableau de bord de ronds de
   progression.
2. Ajouter Fibres, Graisses saturées et Sel à l'affichage (données absentes aujourd'hui de cette
   page).
3. Éliminer la duplication : le rond d'hydratation et les nouveaux ronds de macros doivent
   partager le même composant SVG sous-jacent.
4. Code backend strictement conforme aux conventions déjà en place dans le projet (voir
   `.claude/CLAUDE.md`) — aucune initiative hors du périmètre demandé, pas de goal/feature
   inventés au-delà de ce qui est spécifié ici.
5. Rendu visuel soigné : animations et transitions fluides, cohérent avec un niveau d'exigence
   esthétique "moderne", tout en respectant strictement les tokens de couleur et les classes
   existantes du design system (pas de nouvelle palette, pas de nouveau pattern visuel en dehors
   des extensions explicitement listées ci-dessous).

## Hors scope

- Personnalisation des objectifs fibres/sel/graisses saturées par utilisateur (pas de champ
  `Profile` ajouté).
- Nettoyage du code mort (`_daily_objectives.html.erb` et partials associés).
- Modification du comportement du toggle de saisie d'eau personnalisée
  (`water_widget_controller.js`).
- Toute page autre que le panneau journalier du calendrier (`_daily_panel.html.erb`).

## Design visuel

### Hiérarchie à 2 niveaux

```
┌────────────────────────────────────────────────────────────────┐
│  ⌃ CALORIES                                                      │
│                                                                    │
│        ⭕ Protéines         ⬤⬤⬤          ⭕ Lipides                │
│        ⭕ Glucides         Calories        ⚬ Sel                  │
│            ⌄                (centre,          (badge fixe,        │
│      [Fibres] [Sucres]      le + grand)         valeur brute)     │
│      (apparaît au clic          ⌄                                 │
│       sur Glucides)      [Graisses saturées]                     │
│                          (apparaît au clic                        │
│                           sur Lipides)                             │
└────────────────────────────────────────────────────────────────┘
```

- **Niveau 0 — Calories** : rond central, le plus grand (`:xl`, ~160px). Couleur dynamique selon
  % de l'objectif, reprenant exactement la logique déjà en place sur la barre actuelle
  (`brand` sous l'objectif, `status-success` proche/à l'objectif, `status-danger` au-delà de
  105%).
- **Niveau 1 — Protéines / Glucides (gauche), Lipides (droite)** : taille moyenne (`:md`, ~100px,
  identique au rond hydratation actuel). Protéines et Lipides reprennent la logique de bascule de
  couleur déjà présente sur leurs barres actuelles (proche/à l'objectif → succès, au-delà →
  danger). Glucides reste sur sa couleur macro fixe (`macro-carbs`), comme aujourd'hui.
  Glucides et Lipides affichent un chevron `⌄` discret (`ink-subtle`) indiquant qu'ils sont
  cliquables ; Protéines n'a pas d'enfant, donc pas de chevron.
- **Niveau 2 — Fibres, Sucres (enfants de Glucides), Graisses saturées (enfant de Lipides)** :
  petite taille (`:sm`, ~64px). Sucres conserve son calcul de pourcentage actuel (vs objectif
  glucides journalier). Fibres et Graisses saturées n'ont pas d'objectif : elles affichent la
  valeur brute en grammes, cercle statique (pas d'arc de progression).
- **Sel** : petit rond (`:sm`) toujours visible, positionné à droite près de Lipides, valeur
  brute sans jauge, non cliquable, sans lien hiérarchique parent/enfant (n'appartient
  nutritionnellement à aucune des 3 macros).

### Interaction

- Clic sur le rond Glucides → révèle Fibres + Sucres juste en dessous, avec une transition
  d'ouverture fluide (hauteur + fondu, easing cohérent avec les transitions déjà utilisées dans
  l'app — ex. `transition-all duration-700 ease-out` sur les barres actuelles).
  Clic à nouveau → referme.
- Clic sur le rond Lipides → même comportement pour Graisses saturées.
- Un seul groupe enfant ouvert à la fois n'est pas requis (Glucides et Lipides sont indépendants,
  peuvent être ouverts simultanément).
- Micro-interactions : léger effet d'échelle/opacité au survol des ronds cliquables
  (`hover:scale-105` ou équivalent déjà dans les conventions Tailwind du projet), transition sur
  le remplissage de l'arc SVG identique à celle du rond hydratation actuel
  (`transition: stroke-dashoffset 0.6s ease, stroke 0.4s ease`).

## Architecture technique

### `RingComponent` (nouveau ViewComponent générique)

Remplace le SVG codé en dur du rond hydratation et sert de brique de base pour tous les ronds de
macros.

Paramètres :
- `value:` (Float) — valeur actuelle
- `goal:` (Float, optionnel) — si présent, un arc de progression est dessiné (dasharray/dashoffset,
  logique reprise à l'identique du rond hydratation actuel) ; si absent, cercle statique (trait
  plein, pas d'arc de progression), la valeur brute est affichée au centre
- `size:` (`:xl` / `:md` / `:sm`) — détermine rayon/`stroke-width`/dimensions du SVG et taille du
  texte central (`:xl` ~160px reprend l'échelle du rond hydratation actuel à ~110px mais plus
  grand ; `:md` = dimensions identiques au rond hydratation actuel ; `:sm` ~64px)
- `color:` — token Tailwind à utiliser pour le trait de progression (ou couleur fixe si logique de
  bascule succès/danger)
- `label:` — texte affiché sous/dans le rond (ex. "Protéines")
- `unit:` — unité affichée à côté de la valeur (`"kcal"`, `"g"`)

### Refactor du rond hydratation

`_water_widget.html.erb` est modifié pour utiliser `RingComponent` au lieu de son SVG inline.
Le comportement visuel et fonctionnel reste strictement identique (mêmes seuils de statut, même
distance de perçage, aucun changement de comportement du formulaire de saisie personnalisée). Les
couleurs actuellement codées en dur en hexadécimal (`#22C55E`, `#3B82F6`, `#F59E0B`, `#EF4444`,
`#3F3F46`) sont remplacées par les tokens Tailwind correspondants déjà définis dans le design
system (`status-success`, `status-info`, `status-warning`, `status-danger`, `surface-hover`) — ce
sont les mêmes couleurs, seulement exprimées via les tokens au lieu de valeurs brutes, conformément
à la règle du projet interdisant les couleurs Tailwind brutes.

### `MacroDashboardComponent` (nouveau ViewComponent de composition)

Assemble les instances de `RingComponent` selon la hiérarchie décrite ci-dessus et gère la
disposition (grille/flex). Remplace le contenu actuel de `_daily_panel.html.erb` (le bloc de
barres de progression est supprimé).

### Interaction — Stimulus

Nouveau contrôleur Stimulus (`ring_detail_controller.js`) : toggle d'affichage d'un conteneur
enfant au clic sur un rond parent, transition CSS (`max-height`/`opacity`). Suit les conventions
déjà en place dans `app/javascript/controllers/CLAUDE.md` (scoping, targets, actions).

## Pipeline de données backend

1. **`DayFood`** : ajout de `total_fiber`, `total_saturated_fat`, `total_salt`, sur le même modèle
   que `total_calories` déjà présent (scaling par `gram_factor`).
2. **`CalendarDataLoader#load_items`** : extension de l'accumulateur pour sommer ces 3 valeurs sur
   la journée, à partir de `DayFood` et `DayRecipe` (ce dernier expose déjà l'agrégation via
   `Recipe#total_fiber` / `#total_saturated_fat` / `#total_salt`).
3. Aucun nouveau champ `Profile` n'est ajouté — fibres/graisses saturées/sel sont affichés en
   valeur brute, sans pourcentage d'objectif.

## Design tokens

Ajout dans `colors.macro` (`config/tailwind.config.js`), en suivant la convention de nommage déjà
en place :
- `macro-fiber`
- `macro-saturated-fat`
- `macro-salt`

Sucres réutilise le token `macro-sugars` déjà existant. Aucune autre nouvelle couleur, aucun
nouveau pattern visuel (bordures, ombres, espacement) en dehors de ces 3 tokens.

## Internationalisation

Les libellés (Protéines, Glucides, Fibres, Sucres, Lipides, Graisses saturées, Sel) passent par
`I18n.t()`, ajoutés en synchronisation dans `config/locales/fr/` et `config/locales/en/`, suivant
la convention déjà en place pour cette page.
