class Profile < ApplicationRecord
  extend Enumerize

  GENDERS = %i[male female other].freeze
  ACTIVITY_LEVELS = %i[sedentary lightly_active moderately_active very_active extremely_active].freeze
  GOALS = %i[weight_loss maintenance muscle_gain].freeze

  enumerize :gender, in: GENDERS, predicates: true, scope: true
  enumerize :activity_level, in: ACTIVITY_LEVELS, predicates: true, scope: true
  enumerize :goal, in: GOALS, predicates: true, scope: true

  belongs_to :user

  validates :name, length: { maximum: 30 }
  validates :weight, numericality: { greater_than: 0, less_than: 500 }, allow_blank: true
  validates :height, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  validates :age, numericality: { greater_than: 0, less_than: 120 }, allow_blank: true


  def activity_level_multiplier
    case activity_level
    when 'sedentary'
      return 1.2
    when 'lightly_active'
      return 1.375
    when 'moderately_active'
      return 1.55
    when 'very_active'
      return 1.725
    when 'extremely_active'
      return 1.9
    else
      return 1.2
    end
  end

  def calculate_calories_needed_maintenance
    return nil unless weight.present? && height.present? && age.present?

    daily_calorie_requirement = Dentaku::Calculator.new
    result = daily_calorie_requirement.evaluate("(10 * #{weight} + 6.25 * #{height} - 5 * #{age} + 5) * #{activity_level_multiplier}")
    result.round
  end

  def calculate_calories_needed_weight_loss
    maintenance_calories = calculate_calories_needed_maintenance
    return nil unless maintenance_calories
    (maintenance_calories * 0.85).round
  end

  def calculate_calories_needed_muscle_gain
    maintenance_calories = calculate_calories_needed_maintenance
    return nil unless maintenance_calories
    (maintenance_calories * 1.15).round
  end

  def calories_needed_for_goal
    return nil unless weight.present? && height.present? && age.present?

    if goal.weight_loss?
      calculate_calories_needed_weight_loss
    elsif goal.maintenance?
      calculate_calories_needed_maintenance
    elsif goal.muscle_gain?
      calculate_calories_needed_muscle_gain
    else
      calculate_calories_needed_maintenance
    end
  end

  def daily_protein_goal
    return nil unless weight.present?
    weight * 2
  end

  def daily_fats_goal
    return nil unless weight.present?
    weight * 1
  end
end
