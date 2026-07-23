class BackfillProgramExerciseSets < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  class ProgramExercise < ActiveRecord::Base
  end

  class ProgramExerciseSet < ActiveRecord::Base
  end

  def up
    ProgramExercise.find_each do |pe|
      count = pe.sets || 1
      count.times do |i|
        ProgramExerciseSet.create!(
          program_exercise_id: pe.id,
          position: i,
          reps_target: pe.reps_target || 10,
          weight_target: pe.weight_target,
          set_types: []
        )
      end
    end
  end

  def down
    ProgramExerciseSet.delete_all
  end
end
