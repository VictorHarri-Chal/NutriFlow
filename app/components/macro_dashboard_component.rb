# frozen_string_literal: true

##
# Assemble les RingComponent du panneau calories : protéines/glucides/lipides
# à gauche, calories au centre, fibres/sucres/graisses saturées/sel à droite
# (valeurs informatives, sans jauge), le tout sur une seule ligne horizontale.
#
# Palette volontairement restreinte : les 4 anneaux avec objectif (calories,
# protéines, glucides, lipides) partagent tous le même code couleur sémantique
# à 3 états (feu tricolore) — vert/orange/rouge via les tokens status-* —
# plutôt qu'une couleur distincte par macro. La sémantique (adaptée à l'objectif
# de l'utilisateur) est portée par Profile#ring_status, seule source de vérité,
# cohérente avec Profile#daily_goals_met?. Ce composant ne fait que traduire le
# statut en classe de couleur. Les 4 anneaux informatifs (fibres/sucres/ac.
# saturés/sel) partagent eux une seule couleur neutre.
class MacroDashboardComponent < ApplicationComponent
  NEUTRAL_DETAIL_COLOR = "stroke-ink-subtle"

  RING_STATUS_STROKE = {
    success: "stroke-status-success",
    warning: "stroke-status-warning",
    danger:  "stroke-status-danger"
  }.freeze

  # Les *_percentage (calories/proteins/carbs/fats) ne sont jamais nil tant que ce
  # composant n'est instancié que lorsque daily_calorie_goal est présent (même garde
  # que _daily_panel.html.erb) — CalendarDataLoader ne les calcule que dans ce cas.
  def initialize(profile:, total_calories:, daily_calorie_goal:, calories_percentage:,
                 total_proteins:, daily_protein_goal:, proteins_percentage:,
                 total_carbs:, daily_carbs_goal:, carbs_percentage:,
                 total_fats:, daily_fats_goal:, fats_percentage:,
                 total_sugars:, total_fiber:, total_saturated_fat:, total_salt:)
    @profile             = profile
    @total_calories      = total_calories
    @daily_calorie_goal  = daily_calorie_goal
    @calories_percentage = calories_percentage
    @total_proteins      = total_proteins
    @daily_protein_goal  = daily_protein_goal
    @proteins_percentage = proteins_percentage
    @total_carbs         = total_carbs
    @daily_carbs_goal    = daily_carbs_goal
    @carbs_percentage    = carbs_percentage
    @total_fats          = total_fats
    @daily_fats_goal     = daily_fats_goal
    @fats_percentage     = fats_percentage
    @total_sugars        = total_sugars
    @total_fiber         = total_fiber
    @total_saturated_fat = total_saturated_fat
    @total_salt          = total_salt
  end

  private

  attr_reader :profile,
              :total_calories, :daily_calorie_goal, :calories_percentage,
              :total_proteins, :daily_protein_goal, :proteins_percentage,
              :total_carbs, :daily_carbs_goal, :carbs_percentage,
              :total_fats, :daily_fats_goal, :fats_percentage,
              :total_sugars, :total_fiber, :total_saturated_fat, :total_salt

  def stroke_for(kind, percentage)
    status = profile ? profile.ring_status(kind, percentage) : :warning
    RING_STATUS_STROKE.fetch(status)
  end

  def calories_color_class
    stroke_for(:calories, calories_percentage)
  end

  def proteins_color_class
    stroke_for(:proteins, proteins_percentage)
  end

  def carbs_color_class
    stroke_for(:carbs, carbs_percentage)
  end

  def fats_color_class
    stroke_for(:fats, fats_percentage)
  end
end
