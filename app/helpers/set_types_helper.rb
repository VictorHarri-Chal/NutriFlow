module SetTypesHelper
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

  SET_TYPE_PILL_BASE_CLASSES = {
    sm: "inline-flex items-center px-2.5 py-1 rounded-full text-[9px] font-medium border cursor-pointer transition-colors bg-surface-hover text-ink-muted border-surface-border/40",
    md: "inline-flex items-center px-3 py-1.5 rounded-full text-[10px] font-medium border cursor-pointer transition-colors bg-surface-hover text-ink-muted border-surface-border/40"
  }.freeze

  def set_type_pill_classes(type, size: :sm)
    "#{SET_TYPE_PILL_BASE_CLASSES.fetch(size)} #{SET_TYPE_PILL_ACTIVE_CLASSES.fetch(type, '')}"
  end

  def set_chip_type_label(set)
    labels = RpeSetType::DISPLAY_PRIORITY.select { |type| set.set_types.include?(type) }
    return nil if labels.empty?

    labels.map { |type| I18n.t("views.workout_sets.set_editor.set_types_abbr.#{type}") }.join("+")
  end

  # Shared between workout_sessions/_form.html.erb and
  # workout_programs/_set_fields.html.erb — both render a 6–10 RPE select
  # with the same descriptive labels.
  def rpe_select_options
    (RpeSetType::MIN_RPE..RpeSetType::MAX_RPE).map { |v| [t("views.workout_sets.set_editor.rpe_options.value_#{v}"), v] }
  end
end
