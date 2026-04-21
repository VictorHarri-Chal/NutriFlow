class Exercise < ApplicationRecord
  include PgSearch::Model

  belongs_to :custom_user, class_name: "User", foreign_key: :custom_user_id, optional: true
  has_one_attached :image
  has_many :exercise_favorites, dependent: :destroy

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
  scope :with_gif, -> { where(gif_status: "ok") }
  scope :visible, -> { where(gif_status: [nil, "ok"]) }

  def self.body_parts
    global.distinct.order(:body_part).pluck(:body_part).compact
  end

  def self.equipments
    global.distinct.order(:equipment).pluck(:equipment).compact
  end

  def custom?
    custom_user_id.present?
  end
end
