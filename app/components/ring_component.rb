# frozen_string_literal: true

##
# Rond de progression SVG générique, réutilisé par MacroDashboardComponent
# et le widget hydratation. Deux modes :
#   - mode "progression" (goal présent) : arc de remplissage + % en dessous
#   - mode "valeur brute" (goal absent) : cercle en pointillés (non une jauge), pas de %
#
# Le contenu du centre du rond peut être personnalisé via un bloc ; sans bloc,
# affiche la valeur (+ objectif/unité) par défaut.
class RingComponent < ApplicationComponent
  SIZES = {
    xl: { viewbox: 160, radius: 68, stroke_width: 9, value_text: "text-2xl", unit_text: "text-xs",    goal_text: "text-xs",    label_text: "text-xs",     pct_text: "text-sm"    },
    md: { viewbox: 110, radius: 42, stroke_width: 7, value_text: "text-lg",  unit_text: "text-[9px]", goal_text: "text-[9px]", label_text: "text-[10px]", pct_text: "text-xs"    },
    sm: { viewbox: 76,  radius: 30, stroke_width: 5, value_text: "text-xs",  unit_text: "text-[8px]", goal_text: "text-[8px]", label_text: "text-[9px]",  pct_text: "text-[10px]" }
  }.freeze

  def initialize(value:, color_class:, size: :md, goal: nil, label: nil, unit: "g",
                 percentage_color_class: "text-ink-subtle", value_decimals: nil)
    @value                  = value.to_f
    @goal                   = goal&.to_f
    @size                   = size
    @color_class            = color_class
    @label                  = label
    @unit                   = unit
    @percentage_color_class = percentage_color_class
    @value_decimals         = value_decimals
  end

  private

  attr_reader :value, :goal, :size, :color_class, :label, :unit, :percentage_color_class,
              :value_decimals

  def progress_mode?
    goal.present? && goal > 0
  end

  def percentage
    return nil unless progress_mode?

    (value / goal * 100).round(1)
  end

  def dimensions
    SIZES.fetch(size)
  end

  def viewbox
    dimensions[:viewbox]
  end

  def radius
    dimensions[:radius]
  end

  def stroke_width
    dimensions[:stroke_width]
  end

  def center
    viewbox / 2.0
  end

  def circumference
    (2 * Math::PI * radius).round(2)
  end

  def dashoffset
    return 0 unless progress_mode?

    ratio = [percentage, 100].min / 100.0
    (circumference * (1 - ratio)).round(2)
  end

  def formatted_value
    return value.round.to_s if value_decimals == 0

    format_number(value)
  end

  # Toujours arrondi à l'entier : un objectif ("/ 159 g") n'a jamais de décimale,
  # même quand la valeur courante ("7.5 g") en a une.
  def formatted_goal
    goal ? goal.round.to_s : nil
  end

  def format_number(number)
    number % 1 == 0 ? number.to_i.to_s : number.round(1).to_s
  end
end
