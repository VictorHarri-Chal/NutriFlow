class ResetUserDataJob < ApplicationJob
  queue_as :default

  # If the user was deleted before the job ran, there's nothing to reset.
  discard_on ActiveJob::DeserializationError
  # A concurrent double-submit enqueues two jobs; the loser hits the unique index
  # on profiles.user_id at create_profile! and raises. The winner already reset
  # everything (atomic transaction), so drop the loser instead of failing loudly.
  discard_on ActiveRecord::RecordNotUnique

  # Wipes the user's data off the request cycle: reset_all_data! destroys years
  # of days/foods/recipes/... in one atomic cascade (with R2 blob purges), which
  # would otherwise tie up a web thread. Re-running converges to the same end
  # state (data wiped, one fresh profile).
  def perform(user)
    user.reset_all_data!
  end
end
