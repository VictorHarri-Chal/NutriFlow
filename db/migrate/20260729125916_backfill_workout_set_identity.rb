class BackfillWorkoutSetIdentity < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    say_with_time "Backfill workout_sets identity" do
      WorkoutSet.includes(:exercise).find_each do |s|
        next if s.exercise.nil?
        s.update_columns(exercise_name: s.exercise.name, body_part: s.exercise.body_part)
      end
    end
  end

  def down
    WorkoutSet.update_all(exercise_name: nil, body_part: nil)
  end
end
