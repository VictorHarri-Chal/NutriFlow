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
end
