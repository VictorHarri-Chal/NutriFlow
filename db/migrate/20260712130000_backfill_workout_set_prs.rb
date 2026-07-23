class BackfillWorkoutSetPrs < ActiveRecord::Migration[8.0]
  def up
    User.find_each { |user| PrRecalculator.recompute_all_for(user) }
  end

  def down
    # Irreversible: the previous is_pr values depended on save-time ordering
    # (the buggy "all sessions regardless of date" comparison), not
    # something reconstructible from stored data.
  end
end
