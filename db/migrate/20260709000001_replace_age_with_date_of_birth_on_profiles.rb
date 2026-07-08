class ReplaceAgeWithDateOfBirthOnProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column    :profiles, :date_of_birth, :date
    remove_column :profiles, :age, :integer
  end
end
