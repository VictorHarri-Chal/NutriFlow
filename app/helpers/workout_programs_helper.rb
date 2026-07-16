module WorkoutProgramsHelper
  def rest_seconds_label(rest_seconds)
    mins = rest_seconds / 60
    secs = rest_seconds % 60
    min_abbr = t("views.workout_programs.day.rest_min_abbr")
    sec_abbr = t("views.workout_programs.day.rest_sec_abbr")
    return "#{secs}#{sec_abbr}" if mins.zero?

    "#{mins}#{min_abbr}#{secs.positive? ? "#{secs}#{sec_abbr}" : ''}"
  end
end
