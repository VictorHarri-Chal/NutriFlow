class Exercise < ApplicationRecord
  extend Enumerize
  include PgSearch::Model

  TENSION_PROFILES = %i[stretch contraction mixed].freeze

  belongs_to :custom_user, class_name: "User", foreign_key: :custom_user_id, optional: true
  has_one_attached :image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [400, 400], preprocessed: true
    attachable.variant :medium,    resize_to_limit: [800, 800], preprocessed: true
  end
  has_many :exercise_favorites, dependent: :destroy
  # Les WorkoutSet sont des logs figés (exercise_name/body_part) : supprimer un
  # exercice les DÉTACHE (exercise_id → NULL), l'historique reste intact.
  has_many :workout_sets, dependent: :nullify
  # Les ProgramExercise sont des lignes de template (pas des logs) : on les retire
  # du programme quand l'exercice est supprimé.
  has_many :program_exercises, dependent: :destroy

  after_commit :bust_metadata_cache, if: -> { custom_user_id.nil? }

  enumerize :tension_profile, in: TENSION_PROFILES

  validates :exercise_id, presence: true, uniqueness: true
  validates :name, presence: true

  pg_search_scope :search_by_name,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }

  scope :global, -> { where(custom_user_id: nil) }
  scope :for_user, ->(user) { where(custom_user_id: user.id) }
  scope :accessible_to, ->(user) { where(custom_user_id: [nil, user.id]) }
  scope :by_body_part, ->(part) { where(body_part: part) }
  scope :by_equipment, ->(eq) { where(equipment: eq) }
  scope :by_tension_profile, ->(value) {
    next none unless value.is_a?(String) || value.is_a?(Array)

    value == "none" ? where(tension_profile: nil) : where(tension_profile: value)
  }
  scope :with_gif, -> { where(gif_status: "ok") }
  scope :visible, -> { where(gif_status: [nil, "ok"]) }

  # Global exercise metadata is admin-managed and identical for every user, so
  # the distinct-scan behind the index filter dropdowns is cached rather than
  # re-run on each request.
  def self.body_parts
    Rails.cache.fetch("exercise/body_parts", expires_in: 1.day) do
      global.distinct.order(:body_part).pluck(:body_part).compact
    end
  end

  def self.equipments
    Rails.cache.fetch("exercise/equipments", expires_in: 1.day) do
      global.distinct.order(:equipment).pluck(:equipment).compact
    end
  end

  def custom?
    custom_user_id.present?
  end

  private

  # body_parts/equipments only reflect global exercises, so bust their cache
  # only when a global record changes (a user's custom exercise never affects
  # those lists). Keeps the 1-day cache correct without churn on user writes.
  def bust_metadata_cache
    Rails.cache.delete_multi(["exercise/body_parts", "exercise/equipments"])
  end
end
