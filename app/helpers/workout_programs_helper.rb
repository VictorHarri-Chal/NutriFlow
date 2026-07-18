module WorkoutProgramsHelper
  def rest_seconds_label(rest_seconds)
    mins = rest_seconds / 60
    secs = rest_seconds % 60
    min_abbr = t("views.workout_programs.day.rest_min_abbr")
    sec_abbr = t("views.workout_programs.day.rest_sec_abbr")
    return "#{secs}#{sec_abbr}" if mins.zero?

    "#{mins}#{min_abbr}#{secs.positive? ? "#{secs}#{sec_abbr}" : ''}"
  end

  # "2 étirement · 1 contraction · 1 mixte" style summary for the tension
  # balance panel. Only mentions non-zero buckets.
  def tension_balance_count_label(stretch_count, contraction_count, mixed_count)
    parts = []
    parts << "#{stretch_count} #{t("views.workout_programs.tension_balance.legend.stretch").downcase}" if stretch_count.positive?
    parts << "#{contraction_count} #{t("views.workout_programs.tension_balance.legend.contraction").downcase}" if contraction_count.positive?
    parts << "#{mixed_count} #{t("views.workout_programs.tension_balance.legend.mixed").downcase}" if mixed_count.positive?
    parts.join(" · ")
  end
end
