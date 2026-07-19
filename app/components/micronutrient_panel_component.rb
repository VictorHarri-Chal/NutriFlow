# frozen_string_literal: true

# Dashboard hebdomadaire complet des 14 micronutriments (jamais seulement ceux
# consommés) dans la section Calories du calendrier. Composant séparé de
# MacroDashboardComponent — responsabilité distincte, évite d'alourdir un
# composant déjà chargé de 7 anneaux.
class MicronutrientPanelComponent < ApplicationComponent
  def initialize(coverage:, week_start:, week_end:)
    @coverage   = coverage
    @week_start = week_start
    @week_end   = week_end
  end

  private

  attr_reader :coverage, :week_start, :week_end

  def groups
    [[t_group_minerals, Micronutrient.minerals], [t_group_vitamins, Micronutrient.vitamins]]
  end

  def t_group_minerals = I18n.t("views.foods.show.minerals")
  def t_group_vitamins = I18n.t("views.foods.show.vitamins")

  def bar_color_class(entry, data)
    return "bg-status-danger"  if entry.nature == :ceiling && data[:percentage].to_i > 100
    return "bg-status-success" if entry.nature == :floor   && data[:percentage].to_i >= 100
    "bg-brand"
  end

  def bar_width(data)
    [data[:percentage].to_i, 100].min
  end
end
