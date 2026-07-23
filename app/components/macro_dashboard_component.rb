# frozen_string_literal: true

##
# Assemble les RingComponent du panneau calories : protéines/glucides/lipides
# à gauche, calories au centre, fibres/sucres/graisses saturées/sel à droite
# (valeurs informatives, sans jauge), le tout sur une seule ligne horizontale.
#
# Palette volontairement restreinte : les 4 anneaux avec objectif (calories,
# protéines, glucides, lipides) partagent tous le même code couleur sémantique
# (objectif atteint → vert, dépassé → rouge sauf protéines, sinon → ambre de
# marque) plutôt qu'une couleur distincte par macro — cohérence visuelle avant
# tout. Les 4 anneaux informatifs (fibres/sucres/ac. saturés/sel) partagent eux
# aussi une seule couleur neutre.
class MacroDashboardComponent < ApplicationComponent
  NEUTRAL_DETAIL_COLOR = "stroke-ink-subtle"

  # Les *_percentage (calories/proteins/carbs/fats) ne sont jamais nil tant que ce
  # composant n'est instancié que lorsque daily_calorie_goal est présent (même garde
  # que _daily_panel.html.erb) — CalendarDataLoader ne les calcule que dans ce cas.
  def initialize(total_calories:, daily_calorie_goal:, calories_percentage:,
                 total_proteins:, daily_protein_goal:, proteins_percentage:,
                 total_carbs:, daily_carbs_goal:, carbs_percentage:,
                 total_fats:, daily_fats_goal:, fats_percentage:,
                 total_sugars:, total_fiber:, total_saturated_fat:, total_salt:)
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

  attr_reader :total_calories, :daily_calorie_goal, :calories_percentage,
              :total_proteins, :daily_protein_goal, :proteins_percentage,
              :total_carbs, :daily_carbs_goal, :carbs_percentage,
              :total_fats, :daily_fats_goal, :fats_percentage,
              :total_sugars, :total_fiber, :total_saturated_fat, :total_salt

  # Seuil partagé calories/glucides/lipides : >105% = danger, >=100% = succès,
  # sinon ambre de marque (en cours / insuffisant, mais toujours visible).
  # (Protéines a sa propre règle à 2 paliers seulement — un dépassement de protéines
  # n'est jamais signalé comme négatif — donc pas unifiée ici, cf. proteins_color_class.)
  def bascule_color_class(percentage, base: "stroke-brand")
    return "stroke-status-danger"  if percentage > 105
    return "stroke-status-success" if percentage >= 100

    base
  end

  def calories_color_class
    bascule_color_class(calories_percentage)
  end

  def proteins_color_class
    proteins_percentage >= 100 ? "stroke-status-success" : "stroke-brand"
  end

  def carbs_color_class
    bascule_color_class(carbs_percentage)
  end

  def fats_color_class
    bascule_color_class(fats_percentage)
  end
end
