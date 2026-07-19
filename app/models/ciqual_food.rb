class CiqualFood < ApplicationRecord
  include PgSearch::Model

  validates :alim_code, presence: true, uniqueness: true

  pg_search_scope :search_by_name,
    against: [:name],
    using: { tsearch: { prefix: true } }
end
