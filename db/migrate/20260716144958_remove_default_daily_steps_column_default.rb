class RemoveDefaultDailyStepsColumnDefault < ActiveRecord::Migration[8.0]
  def change
    # The DB-level default pre-fills new records before Profile#set_default_steps
    # (a before_validation callback) ever runs, making its job-baseline logic
    # unreachable. The Ruby callback always sets a value before save, so
    # null: false stays satisfied without a column default.
    change_column_default :profiles, :default_daily_steps, from: 6000, to: nil
  end
end
