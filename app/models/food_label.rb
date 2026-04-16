class FoodLabel < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :foods, join_table: 'food_labels_foods'

  COLORS = %w[red orange amber yellow green teal blue violet].freeze

  COLOR_STYLES = {
    "red"    => { bg: "bg-red-500/20",    text: "text-red-400",    border: "border-red-500/30",    dot: "bg-red-400"    },
    "orange" => { bg: "bg-orange-500/20", text: "text-orange-400", border: "border-orange-500/30", dot: "bg-orange-400" },
    "amber"  => { bg: "bg-amber-400/20",  text: "text-amber-400",  border: "border-amber-400/30",  dot: "bg-amber-400"  },
    "yellow" => { bg: "bg-yellow-400/20", text: "text-yellow-400", border: "border-yellow-400/30", dot: "bg-yellow-400" },
    "green"  => { bg: "bg-green-500/20",  text: "text-green-400",  border: "border-green-500/30",  dot: "bg-green-400"  },
    "teal"   => { bg: "bg-teal-500/20",   text: "text-teal-400",   border: "border-teal-500/30",   dot: "bg-teal-400"   },
    "blue"   => { bg: "bg-blue-500/20",   text: "text-blue-400",   border: "border-blue-500/30",   dot: "bg-blue-400"   },
    "violet" => { bg: "bg-violet-500/20", text: "text-violet-400", border: "border-violet-500/30", dot: "bg-violet-400" },
  }.freeze

  DEFAULT_STYLE = { bg: "bg-brand-muted", text: "text-brand", border: "border-brand/30", dot: "bg-brand" }.freeze

  validates :name, presence: true, length: { maximum: 20 }
  validates :name, uniqueness: { scope: :user_id }
  validates :color, inclusion: { in: COLORS }, allow_nil: true

  scope :for_user, ->(user) { where(user: user) }

  def color_style
    COLOR_STYLES.fetch(color, DEFAULT_STYLE)
  end
end
