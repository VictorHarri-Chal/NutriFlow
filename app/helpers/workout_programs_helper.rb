module WorkoutProgramsHelper
  SET_TYPE_DOT_CLASSES = {
    "warmup"  => "bg-status-success",
    "dropset" => "bg-status-info",
    "failure" => "bg-status-danger",
    nil       => "bg-brand"
  }.freeze

  # Named peers (peer/<type> ↔ peer-checked/<type>:) — with 4 checkboxes in the same
  # sibling list, plain peer-checked: matches ANY earlier checked .peer, not just "its own"
  # checkbox. Each type needs its own named peer or checking one pill visually lights up
  # a different, later pill instead.
  SET_TYPE_PILL_ACTIVE_CLASSES = {
    "warmup"  => "peer-checked/warmup:bg-status-success/20 peer-checked/warmup:text-status-success peer-checked/warmup:border-status-success/50",
    "working" => "peer-checked/working:bg-brand/20 peer-checked/working:text-brand peer-checked/working:border-brand/50",
    "failure" => "peer-checked/failure:bg-status-danger/20 peer-checked/failure:text-status-danger peer-checked/failure:border-status-danger/50",
    "dropset" => "peer-checked/dropset:bg-status-info/20 peer-checked/dropset:text-status-info peer-checked/dropset:border-status-info/50"
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
