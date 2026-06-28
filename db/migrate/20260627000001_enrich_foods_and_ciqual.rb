class EnrichFoodsAndCiqual < ActiveRecord::Migration[8.0]
  def change
    # Extended EU nutrition label fields
    add_column :foods, :fiber,         :decimal, precision: 6, scale: 2
    add_column :foods, :saturated_fat, :decimal, precision: 6, scale: 2
    add_column :foods, :salt,          :decimal, precision: 6, scale: 2

    # OFF-specific scores
    add_column :foods, :ecoscore_grade, :string

    # OFF allergens — native PG text array, queryable with @>
    add_column :foods, :allergens, :string, array: true, default: []
    add_column :foods, :traces,    :string, array: true, default: []

    # Sparse micronutrients — JSONB (most OFF products have none, Ciqual has most)
    # Keys: calcium, iron, magnesium, potassium, sodium, zinc,
    #       vitamin_c, vitamin_d, vitamin_b12, vitamin_a, vitamin_b9,
    #       cholesterol, epa, dha
    add_column :foods, :micronutrients, :jsonb, default: {}

    # Mirror on ciqual_foods for full import
    add_column :ciqual_foods, :fiber,          :decimal, precision: 6, scale: 2
    add_column :ciqual_foods, :saturated_fat,  :decimal, precision: 6, scale: 2
    add_column :ciqual_foods, :salt,           :decimal, precision: 6, scale: 2
    add_column :ciqual_foods, :micronutrients, :jsonb, default: {}
  end
end
