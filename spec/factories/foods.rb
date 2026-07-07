FactoryBot.define do
  factory :food do
    user
    sequence(:name) { |n| "Food #{n}" }
    calories { 100.0 }
    proteins { 10.0 }
    carbs { 10.0 }
    fats { 5.0 }
  end
end
