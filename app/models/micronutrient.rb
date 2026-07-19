# frozen_string_literal: true

# Source de vérité unique pour les 14 micronutriments gérés par l'application
# (minéraux + vitamines). Remplace la liste dupliquée dans OpenFoodFactsService,
# ciqual.rake, foods/_form.html.erb, foods/show.html.erb et RecipeSidebarComponent.
#
# Les AJR (rda_male/rda_female) sont les références journalières ANSES (avis
# 2018-SA-0238, avril 2021) — voir l'annexe du spec pour les sources détaillées.
# nature: :floor (viser au moins ce seuil), :ceiling (ne pas dépasser), :none
# (aucune référence officielle, ex: cholestérol — affiché sans jauge).
class Micronutrient
  Entry = Struct.new(:key, :group, :unit, :nature, :rda_male, :rda_female, keyword_init: true) do
    def label
      I18n.t("views.foods.show.nutrients.#{key}")
    end
  end

  ALL = [
    Entry.new(key: :calcium,     group: :mineral, unit: "mg", nature: :floor,   rda_male: 950,  rda_female: 950),
    Entry.new(key: :iron,        group: :mineral, unit: "mg", nature: :floor,   rda_male: 11,   rda_female: 11),
    Entry.new(key: :magnesium,   group: :mineral, unit: "mg", nature: :floor,   rda_male: 380,  rda_female: 300),
    Entry.new(key: :potassium,   group: :mineral, unit: "mg", nature: :floor,   rda_male: 3500, rda_female: 3500),
    Entry.new(key: :sodium,      group: :mineral, unit: "mg", nature: :ceiling, rda_male: 2300, rda_female: 2300),
    Entry.new(key: :zinc,        group: :mineral, unit: "mg", nature: :floor,   rda_male: 12,   rda_female: 10),
    Entry.new(key: :cholesterol, group: :mineral, unit: "mg", nature: :none,    rda_male: nil,  rda_female: nil),
    Entry.new(key: :vitamin_c,   group: :vitamin, unit: "mg", nature: :floor,   rda_male: 110,  rda_female: 110),
    Entry.new(key: :vitamin_d,   group: :vitamin, unit: "µg", nature: :floor,   rda_male: 15,   rda_female: 15),
    Entry.new(key: :vitamin_b12, group: :vitamin, unit: "µg", nature: :floor,   rda_male: 4,    rda_female: 4),
    Entry.new(key: :vitamin_a,   group: :vitamin, unit: "µg", nature: :floor,   rda_male: 750,  rda_female: 650),
    Entry.new(key: :vitamin_b9,  group: :vitamin, unit: "µg", nature: :floor,   rda_male: 330,  rda_female: 330),
    Entry.new(key: :epa,         group: :vitamin, unit: "g",  nature: :floor,   rda_male: 0.25, rda_female: 0.25),
    Entry.new(key: :dha,         group: :vitamin, unit: "g",  nature: :floor,   rda_male: 0.25, rda_female: 0.25)
  ].freeze

  KEYS = ALL.map(&:key).freeze

  def self.find(key) = ALL.find { |entry| entry.key == key.to_sym }
  def self.minerals  = ALL.select { |entry| entry.group == :mineral }
  def self.vitamins  = ALL.select { |entry| entry.group == :vitamin }

  def self.coverage_percentage(value, goal)
    return nil unless goal && goal > 0
    (value.to_f / goal * 100).round
  end
end
