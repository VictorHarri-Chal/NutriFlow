class ChangeDefaultSetTypesToWorkingOnProgramExerciseSets < ActiveRecord::Migration[8.0]
  def up
    change_column_default :program_exercise_sets, :set_types, from: [], to: ["working"]
    execute <<~SQL
      UPDATE program_exercise_sets SET set_types = ARRAY['working'] WHERE set_types = ARRAY[]::varchar[]
    SQL
  end

  def down
    change_column_default :program_exercise_sets, :set_types, from: ["working"], to: []
  end
end
