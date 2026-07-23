module ShoppingListsHelper
  CATEGORY_ICONS = {
    "proteins"    => "fa-drumstick-bite",
    "grains"      => "fa-bread-slice",
    "vegetables"  => "fa-carrot",
    "fruits"      => "fa-apple-whole",
    "dairy"       => "fa-cheese",
    "beverages"   => "fa-glass-water",
    "condiments"  => "fa-mortar-pestle",
    "supplements" => "fa-capsules",
    "other"       => "fa-box"
  }.freeze

  def shopping_category_icon(category)
    CATEGORY_ICONS[category] || CATEGORY_ICONS["other"]
  end
end
