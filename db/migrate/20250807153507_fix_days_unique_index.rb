class FixDaysUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    # Supprimer l'ancien index unique sur date
    remove_index :days, :date

    # Ajouter un index unique sur date et user_id
    add_index :days, [:date, :user_id], unique: true
  end
end
