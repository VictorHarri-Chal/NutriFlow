class WorkoutSet < ApplicationRecord
  include RpeSetType

  belongs_to :workout_session
  belongs_to :exercise, optional: true

  # exercise_id peut être NULL après suppression d'un exercice (FK :nullify) :
  # un set détaché reste valide tant qu'il a son identité figée (exercise_name).
  validates :exercise_id, presence: true, unless: -> { exercise_name.present? }
  validates :reps, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :weight_kg, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :exercise_accessible_to_user
  validate :exercise_reference_must_resolve

  before_save :capture_exercise_identity, if: :should_capture_exercise_identity?

  # Identité figée au log ; repli sur l'exercice vivant tant que le figé n'a pas
  # encore été capturé (nouveau set avant save) ou pour un exercice encore présent.
  def display_exercise_name = exercise_name.presence || exercise&.name
  def display_body_part     = body_part.presence || exercise&.body_part

  # Série détachée : l'exercice a été supprimé (exercise_id nullifié), le nom +
  # la partie du corps figés subsistent.
  def detached? = exercise_id.nil? && exercise_name.present?

  private

  def should_capture_exercise_identity?
    exercise.present? && (exercise_name.blank? || (persisted? && will_save_change_to_exercise_id?))
  end

  def capture_exercise_identity
    self.exercise_name = exercise.name
    self.body_part     = exercise.body_part
  end

  def exercise_accessible_to_user
    return unless exercise && workout_session&.day

    errors.add(:exercise, :invalid) unless Exercise.accessible_to(workout_session.day.user).exists?(exercise.id)
  end

  # Un exercise_id fourni doit résoudre un Exercise existant (sauf set détaché
  # déjà figé) — sinon capture_exercise_identity planterait sur un exercise nil.
  def exercise_reference_must_resolve
    errors.add(:exercise_id, :invalid) if exercise_id.present? && exercise.blank?
  end
end
