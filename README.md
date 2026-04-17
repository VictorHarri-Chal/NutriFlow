# NutriFlow — Nutrition & Entraînement

Application de suivi nutritionnel et d'entraînement personnelle. Suivez votre alimentation au quotidien, créez vos recettes, et explorez une banque de plus de 1 100 exercices avec GIFs animés.

---

## Fonctionnalités

### Nutrition
| Fonctionnalité         | Description                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------------- |
| Calendrier alimentaire | Ajout d'aliments et de recettes par jour, groupes de repas configurables, résumé macro en temps réel |
| Banque d'aliments      | Création, recherche (pg_search + Ransack), filtres par étiquettes, pagination                        |
| Recettes               | Recettes multi-ingrédients avec calcul nutritionnel automatique et notation personnelle              |
| Objectifs journaliers  | Calcul BMR Mifflin-St Jeor via Dentaku, objectifs caloriques/macros selon le profil                  |
| Profil & paramètres    | Poids, taille, âge, sexe, niveau d'activité, objectif (perte de poids / maintien / prise de masse)   |

### Entraînement
| Fonctionnalité           | Description                                                                                             |
| ------------------------ | ------------------------------------------------------------------------------------------------------- |
| Banque d'exercices       | +1 100 exercices seedés depuis ExerciseDB — GIFs animés (hover), muscles ciblés, instructions pas à pas |
| Filtres avancés          | Filtres par groupe musculaire, équipement et niveau de difficulté (débutant / intermédiaire / avancé)   |
| Recherche plein texte    | pg_search sur le nom des exercices avec préfixe                                                         |
| Exercices personnalisés  | Création d'exercices custom (user-scoped) avec upload d'image Active Storage                            |

---

## Stack

| Catégorie                 | Outil                                                      |
| ------------------------- | ---------------------------------------------------------- |
| Framework                 | Ruby on Rails 8.0.2                                        |
| Base de données           | PostgreSQL                                                 |
| Frontend                  | Tailwind CSS v3, Hotwire (Turbo + Stimulus), ViewComponent |
| Auth / Forms / Pagination | Devise, Simple Form, Pagy                                  |
| Recherche                 | pg_search, Ransack                                         |
| Calculs BMR               | Dentaku (évaluateur d'expressions runtime)                 |
| Stockage fichiers         | Active Storage (images exercices custom)                   |
| Déploiement               | Kamal (Docker)                                             |

---

## Prérequis

- Ruby **3.4.2**
- PostgreSQL >= 14
- Node.js (pour Tailwind en développement)

---

## Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/VictorHarri-Chal/NutriFlow
cd NutriFlow

# 2. Installer les dépendances
bundle install

# 3. Configurer les variables d'environnement
cp .env.example .env
# Renseigner DATABASE_URL ou les identifiants PostgreSQL locaux

# 4. Créer et migrer la base
bin/rails db:create db:migrate

# 5. Lancer le serveur (Rails + Tailwind en parallèle)
bin/dev
```

L'application est accessible sur `http://localhost:3000`.

---

## Seed des exercices

La banque d'exercices est seedée en une seule fois depuis l'API ExerciseDB (tier gratuit, 500 req/mois).

```bash
# Importer les exercices (nécessite RAPIDAPI_KEY dans .env)
bin/rails exercises:seed

# Traduire les descriptions en français via DeepL (optionnel)
bin/rails exercises:translate

# Télécharger les GIFs manquants (optionnel)
bin/rails "exercises:fetch_gifs[500]"
```

> **En production :** Après le seed local, exporter les données et les importer directement sans appel API :
> ```bash
> # Export local
> pg_dump nutriflow_development --table=exercises --data-only --no-owner -f db/seeds/exercises.sql
>
> # Import production
> psql $DATABASE_URL < db/seeds/exercises.sql
> ```

---

## Variables d'environnement

| Variable                       | Usage                                   | Requis en production |
| ------------------------------ | --------------------------------------- | -------------------- |
| `NUTRI_FLOW_DATABASE_PASSWORD` | Mot de passe PostgreSQL en production   | ✅                   |
| `RAILS_MASTER_KEY`             | Clé de déchiffrement des credentials    | ✅                   |
| `DATABASE_URL`                 | URL complète de connexion (alternative) | Optionnel            |
| `RAPIDAPI_KEY`                 | Clé API RapidAPI (seed exercices)       | Seed uniquement      |
| `DEEPL_API_KEY`                | Clé DeepL (traduction exercices)        | Seed uniquement      |

---

## Déploiement

Le projet cible un déploiement **Kamal** (Docker). La configuration est dans `config/deploy.yml`.

```bash
kamal deploy
```

---

## Auteur

[Victor Harri-Chal](https://github.com/VictorHarri-Chal)
