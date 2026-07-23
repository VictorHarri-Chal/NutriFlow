module Exports
  # Not date-scoped: always exports the profile's current state (period: is
  # accepted only so every exporter shares the same call signature).
  class ProfileExporter
    def initialize(user:, period: nil)
      @user = user
    end

    def sheets
      profile = @user.profile
      return [] unless profile

      headers = [
        "Nom", "Date de naissance", "Âge", "Genre", "Taille (cm)", "Poids actuel (kg)",
        "Niveau d'activité", "Objectif", "Poids cible (kg)", "Rythme visé (kg/semaine)",
        "BMR", "TDEE de base", "Objectif calorique", "Objectif protéines (g)",
        "Objectif lipides (g)", "Objectif glucides (g)", "Objectif eau (ml)", "Objectif pas"
      ]

      row = [
        profile.name, profile.date_of_birth, profile.age, profile.gender&.text,
        profile.height, profile.weight, profile.job_activity_level&.text, profile.goal&.text,
        profile.goal_weight, profile.goal_rate_kg_per_week, profile.bmr, profile.base_tdee,
        profile.calories_needed_for_goal, profile.daily_protein_goal,
        profile.daily_fats_goal, profile.daily_carbs_goal, profile.water_goal_ml,
        profile.default_daily_steps
      ]

      [Exports::Sheet.simple(name: "Profil", headers: headers, rows: [row])]
    end
  end
end
