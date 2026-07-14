module WorkoutProgramsHelper
  SET_TYPE_DOT_CLASSES = {
    "warmup"  => "bg-ink-subtle/60",
    "dropset" => "bg-status-info",
    "failure" => "bg-status-danger",
    nil       => "bg-brand"
  }.freeze

  SET_TYPE_PILL_ACTIVE_CLASSES = {
    "warmup"  => "peer-checked:bg-ink-subtle/20 peer-checked:text-ink-subtle peer-checked:border-ink-subtle/40",
    "working" => "peer-checked:bg-brand/20 peer-checked:text-brand peer-checked:border-brand/50",
    "failure" => "peer-checked:bg-status-danger/20 peer-checked:text-status-danger peer-checked:border-status-danger/50",
    "dropset" => "peer-checked:bg-status-info/20 peer-checked:text-status-info peer-checked:border-status-info/50"
  }.freeze

  def set_type_dot_class(dominant_type)
    SET_TYPE_DOT_CLASSES.fetch(dominant_type, SET_TYPE_DOT_CLASSES[nil])
  end

  def set_type_pill_classes(type)
    base = "inline-flex items-center px-2.5 py-1 rounded-full text-[9px] font-medium border cursor-pointer transition-colors bg-surface-hover text-ink-muted border-surface-border/40"
    "#{base} #{SET_TYPE_PILL_ACTIVE_CLASSES.fetch(type, '')}"
  end

  def set_chip_type_label(set)
    labels = ProgramExerciseSet::DISPLAY_PRIORITY.select { |type| set.set_types.include?(type) }
    return nil if labels.empty?

    labels.map { |type| I18n.t("views.workout_programs.set_editor.set_types_abbr.#{type}") }.join("+")
  end

  def rest_seconds_label(rest_seconds)
    mins = rest_seconds / 60
    secs = rest_seconds % 60
    min_abbr = t("views.workout_programs.day.rest_min_abbr")
    sec_abbr = t("views.workout_programs.day.rest_sec_abbr")
    return "#{secs}#{sec_abbr}" if mins.zero?

    "#{mins}#{min_abbr}#{secs.positive? ? "#{secs}#{sec_abbr}" : ''}"
  end
end
