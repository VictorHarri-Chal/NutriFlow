class DayRecipe < ApplicationRecord
  include ValidatesSharedOwner

  # Saisie transitoire au moment du log : "quelle quantité de la recette ?".
  # Sert uniquement à semer les day_recipe_items ; n'est jamais lu pour les
  # totaux (source de vérité = les items). Non persisté (cf. drop des colonnes).
  attr_accessor :log_quantity, :log_use_whole

  belongs_to :day
  belongs_to :recipe, optional: true
  belongs_to :day_food_group, optional: true
  has_many :day_recipe_items, dependent: :destroy, inverse_of: :day_recipe

  accepts_nested_attributes_for :day_recipe_items, allow_destroy: true, reject_if: :all_blank

  # On capture le nombre de lignes soumises AVANT que Rails ne jette les nouvelles
  # lignes marquées _destroy (qu'il ne construit jamais). Sans ça, "des lignes
  # soumises puis toutes supprimées" est indiscernable de "aucune ligne soumise",
  # et needs_seeding? re-sèmerait la recette entière en douce (cf. seed).
  def day_recipe_items_attributes=(attributes)
    rows = attributes.respond_to?(:values) ? attributes.values : Array(attributes)
    @submitted_item_count = rows.count(&:present?)
    super
  end

  before_validation :seed_items_from_recipe, on: :create, if: :needs_seeding?
  before_validation :capture_recipe_name

  # Une recette est requise pour logger, SAUF pour un log déjà figé dont la
  # recette a été supprimée (recipe_id nil mais recipe_name présent — copy hier).
  validates :recipe, presence: true, on: :create, if: -> { recipe_name.blank? }
  validates_shared_owner :recipe, owner: :day
  validate :day_food_group_belongs_to_user, if: -> { day_food_group_id.present? && day.present? }
  validate :must_have_at_least_one_ingredient

  after_save    :recompute_day_totals
  after_destroy :recompute_day_totals

  # ── Interface duck-typée avec DayFood ────────────────────────────────────────
  def food      = recipe
  def food_name = recipe_name

  # Log détaché : la recette a été supprimée (recipe_id nullifié), les items
  # figés + le nom figé subsistent.
  def detached? = recipe_id.nil? && recipe_name.present?

  # attr_accessor brut (jamais casté par Rails) : utilisé à la fois par le
  # seeding et par la vue (checked:/disabled: sur la case à cocher).
  def log_use_whole? = ActiveModel::Type::Boolean.new.cast(log_use_whole)

  # ── Totaux (somme des items figés) ───────────────────────────────────────────
  def total_calories      = computed_totals[:calories]
  def total_proteins      = computed_totals[:proteins]
  def total_carbs         = computed_totals[:carbs]
  def total_fats          = computed_totals[:fats]
  def total_sugars        = computed_totals[:sugars]
  def total_fiber         = computed_totals[:fiber]
  def total_saturated_fat = computed_totals[:saturated_fat]
  def total_salt          = computed_totals[:salt]

  def scaled_micronutrients
    @scaled_micronutrients ||= day_recipe_items.each_with_object({}) do |item, acc|
      item.scaled_micronutrients.each { |key, value| acc[key] = (acc[key] || 0) + value }
    end.transform_values { |v| v.round(2) }
  end

  def total_weight = day_recipe_items.sum(&:grams_equivalent).round(1)

  def display_quantity = "#{total_weight} g"

  private

  # On sème seulement quand AUCUNE ligne n'a été soumise (l'utilisateur a choisi
  # une recette sans toucher aux ingrédients). Si des lignes ont été soumises puis
  # toutes marquées pour suppression, on ne re-sème PAS : must_have_at_least_one_ingredient
  # doit alors rejeter proprement (sinon on reloggerait la recette entière en douce).
  def needs_seeding?
    recipe.present? && day_recipe_items.empty? && @submitted_item_count.to_i.zero?
  end

  # Copie les ingrédients de la recette (en grammes) mis à l'échelle de la
  # quantité loggée. Chaque item figera son propre food_snapshot au save.
  def seed_items_from_recipe
    # Hors "recette entière", une quantité vide ou nulle est une erreur explicite,
    # sinon on loggerait silencieusement la recette entière.
    if !log_use_whole? && log_quantity.to_f <= 0
      errors.add(:base, I18n.t("activerecord.errors.models.day_recipe.quantity_required"))
      return
    end

    total = recipe.total_weight.to_f
    factor = (log_use_whole? || total.zero?) ? 1.0 : (log_quantity.to_f / total)

    recipe.recipe_items.each do |ri|
      day_recipe_items.build(
        food:     ri.food,
        quantity: (ri.grams_equivalent * factor).round(1),
        unit:     "g"
      )
    end
  end

  def capture_recipe_name
    self.recipe_name = recipe.name if recipe_name.blank? && recipe.present?
  end

  def day_food_group_belongs_to_user
    unless day.user.day_food_groups.exists?(day_food_group_id)
      errors.add(:day_food_group, :invalid)
    end
  end

  # Keep the day's denormalized totals in sync. Covers day_recipe_item edits too,
  # which are always persisted through this record's nested-attributes save.
  # Defensive guard against updating an already-destroyed day.
  def recompute_day_totals
    day.recompute_totals! unless day.destroyed?
  end

  def must_have_at_least_one_ingredient
    return if errors[:base].any? || errors[:recipe].any?
    if day_recipe_items.reject(&:marked_for_destruction?).empty?
      errors.add(:base, I18n.t("activerecord.errors.models.day_recipe.at_least_one_ingredient"))
    end
  end

  # Mémorisé, arrondi une seule fois à la fin (cohérence de précision).
  def computed_totals
    @computed_totals ||= day_recipe_items.each_with_object(
      { calories: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, sugars: 0.0,
        fiber: 0.0, saturated_fat: 0.0, salt: 0.0 }
    ) do |item, acc|
      acc[:calories]      += item.total_calories
      acc[:proteins]      += item.total_proteins
      acc[:carbs]         += item.total_carbs
      acc[:fats]          += item.total_fats
      acc[:sugars]        += item.total_sugars
      acc[:fiber]         += item.total_fiber
      acc[:saturated_fat] += item.total_saturated_fat
      acc[:salt]          += item.total_salt
    end.transform_values { |v| v.round(1) }
  end
end
