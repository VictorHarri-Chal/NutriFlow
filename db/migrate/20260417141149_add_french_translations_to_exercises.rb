class AddFrenchTranslationsToExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :exercises, :name_fr, :text
    add_column :exercises, :description_fr, :text
    add_column :exercises, :instructions_fr, :text
  end
end
