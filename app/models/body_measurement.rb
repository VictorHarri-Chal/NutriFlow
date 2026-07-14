class BodyMeasurement < ApplicationRecord
  belongs_to :user

  has_one_attached :image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [400, 400]
    attachable.variant :medium,    resize_to_limit: [800, 800]
  end

  MEASUREMENT_FIELDS = %i[waist_cm hips_cm chest_cm biceps_cm thighs_cm calves_cm neck_cm].freeze

  # US Navy circumference method (metric, cm) - Hodgdon & Beckett (1984)
  # regression formula, as adopted by the US Navy Body Composition Assessment.
  US_NAVY_REGRESSION_MULTIPLIER     = 495
  US_NAVY_REGRESSION_OFFSET         = 450
  US_NAVY_MALE_CONSTANT             = 1.0324
  US_NAVY_MALE_WAIST_NECK_COEF      = 0.19077
  US_NAVY_MALE_HEIGHT_COEF          = 0.15456
  US_NAVY_FEMALE_CONSTANT           = 1.29579
  US_NAVY_FEMALE_WAIST_HIP_NECK_COEF = 0.35004
  US_NAVY_FEMALE_HEIGHT_COEF        = 0.22100

  validates :date, presence: true, uniqueness: { scope: :user_id }
  validate  :date_not_in_future
  validate  :at_least_one_measurement_present

  MEASUREMENT_FIELDS.each do |field|
    validates field, numericality: { greater_than: 0, less_than: 300 }, allow_nil: true
  end

  scope :ordered,    -> { order(:date) }
  scope :for_period, ->(from, to) { ordered.where(date: from..to) }

  def waist_hip_ratio
    return nil unless waist_cm.present? && hips_cm.present?

    (waist_cm / hips_cm).round(2)
  end

  def waist_height_ratio
    height = user.profile&.height
    return nil unless waist_cm.present? && height.present? && height.to_f > 0

    (waist_cm / height).round(2)
  end

  # Formule US Navy (métrique, cm) - nécessite waist_cm + neck_cm
  # (+ hips_cm pour les femmes) + Profile#height + Profile#gender
  def estimated_body_fat_percentage
    height = user.profile&.height
    gender = user.profile&.gender
    return nil unless waist_cm.present? && neck_cm.present? && height.present? && height.to_f > 0 && gender.present?

    case gender.to_sym
    when :male
      diff = waist_cm - neck_cm
      return nil unless diff.positive?

      (US_NAVY_REGRESSION_MULTIPLIER /
        (US_NAVY_MALE_CONSTANT - US_NAVY_MALE_WAIST_NECK_COEF * Math.log10(diff) +
          US_NAVY_MALE_HEIGHT_COEF * Math.log10(height)) - US_NAVY_REGRESSION_OFFSET).round(1)
    when :female
      return nil unless hips_cm.present?

      diff = waist_cm + hips_cm - neck_cm
      return nil unless diff.positive?

      (US_NAVY_REGRESSION_MULTIPLIER /
        (US_NAVY_FEMALE_CONSTANT - US_NAVY_FEMALE_WAIST_HIP_NECK_COEF * Math.log10(diff) +
          US_NAVY_FEMALE_HEIGHT_COEF * Math.log10(height)) - US_NAVY_REGRESSION_OFFSET).round(1)
    end
  end

  private

  def date_not_in_future
    return unless date.present? && date > Date.today

    errors.add(:date, :invalid)
  end

  def at_least_one_measurement_present
    return if MEASUREMENT_FIELDS.any? { |f| public_send(f).present? }

    errors.add(:base, :no_measurement_present)
  end
end
