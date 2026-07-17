module ExercisesHelper
  DIFFICULTY_CLASSES = {
    "beginner"     => "bg-green-500/15 text-green-400 border border-green-500/25",
    "intermediate" => "bg-amber-500/15 text-amber-400 border border-amber-500/25",
    "advanced"     => "bg-red-500/15 text-red-400 border border-red-500/25",
  }.freeze

  def difficulty_badge_classes(difficulty)
    DIFFICULTY_CLASSES[difficulty.to_s.downcase] || "bg-surface-hover text-ink-muted border border-surface-border/40"
  end

  # Font Awesome icon per tension profile — "mixed" is intentionally excluded,
  # the pill is never rendered for it (see #tension_profile_visible?).
  TENSION_PROFILE_ICONS = {
    "stretch"     => "fa-expand",
    "contraction" => "fa-compress",
  }.freeze

  def tension_profile_icon(tension_profile)
    TENSION_PROFILE_ICONS.fetch(tension_profile.to_s)
  end

  # Only stretch/contraction are shown — "mixed" (the default for compound
  # movements) and nil (not yet classified) are not informative to the user.
  def tension_profile_visible?(tension_profile)
    tension_profile.to_s.in?(%w[stretch contraction])
  end

  # Translate a body_part value (e.g. "upper arms") using the i18n locale file.
  # Falls back to the raw string if no key is found.
  def t_body_part(body_part)
    key = body_part.to_s.downcase.gsub(" ", "_")
    t("views.exercises.body_parts.#{key}", default: body_part.to_s.capitalize)
  end

  # Translate an equipment value (e.g. "leverage machine") using the i18n locale file.
  def t_equipment(equipment)
    key = equipment.to_s.downcase.gsub(" ", "_")
    t("views.exercises.equipment.#{key}", default: equipment.to_s.capitalize)
  end

  # Translate a category value (e.g. "strength") using the i18n locale file.
  def t_category(category)
    t("views.exercises.categories.#{category.to_s.downcase}", default: category.to_s.capitalize)
  end

  # Translate a muscle name (e.g. "levator scapulae") using the i18n locale file.
  def t_muscle(muscle)
    key = muscle.to_s.downcase.gsub(" ", "_")
    t("views.exercises.muscles.#{key}", default: muscle.to_s.capitalize)
  end

  # Returns the display image URL: Active Storage upload first, then gif_url fallback.
  # Variants are served via direct CDN URL (bypasses the Rails redirect controller).
  # Returns nil if the blob is missing from storage (e.g. manually deleted from R2).
  def exercise_image_url(exercise, variant: nil)
    if exercise.image.attached?
      if variant
        exercise.image.variant(variant).processed.url
      else
        exercise.image.url
      end
    elsif exercise.gif_url.present?
      exercise.gif_url
    end
  rescue ActiveStorage::Error, Aws::S3::Errors::ServiceError
    nil
  end

  # Exercise names are always kept in English (universal gym terminology).
  def exercise_name(exercise)
    exercise.name
  end

  # Return the localised description.
  def exercise_description(exercise)
    (I18n.locale == :fr && exercise.description_fr.present?) ? exercise.description_fr : exercise.description
  end

  # Return the localised instructions (newline-separated string).
  def exercise_instructions(exercise)
    (I18n.locale == :fr && exercise.instructions_fr.present?) ? exercise.instructions_fr : exercise.instructions
  end

  # "2 étirement · 1 contraction" style summary for the tension balance panel.
  # Only mentions non-zero buckets; omits "mixed" entirely — it isn't
  # actionable information for the user, just the neutral default.
  def tension_balance_count_label(stretch_count, contraction_count, _mixed_count)
    parts = []
    parts << "#{stretch_count} #{t("views.workout_programs.tension_balance.legend.stretch").downcase}" if stretch_count.positive?
    parts << "#{contraction_count} #{t("views.workout_programs.tension_balance.legend.contraction").downcase}" if contraction_count.positive?
    parts.join(" · ")
  end
end
