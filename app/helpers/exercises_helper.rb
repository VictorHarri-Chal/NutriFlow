module ExercisesHelper
  DIFFICULTY_CLASSES = {
    "beginner"     => "bg-green-500/15 text-green-400 border border-green-500/25",
    "intermediate" => "bg-amber-500/15 text-amber-400 border border-amber-500/25",
    "advanced"     => "bg-red-500/15 text-red-400 border border-red-500/25",
  }.freeze

  def difficulty_badge_classes(difficulty)
    DIFFICULTY_CLASSES[difficulty.to_s.downcase] || "bg-surface-hover text-ink-muted border border-surface-border/40"
  end

  # Translate a body_part value (e.g. "upper arms") using the i18n locale file.
  # Falls back to the raw string if no key is found.
  #
  # blank? guard is required, not cosmetic: a blank value would build the key
  # "views.exercises.body_parts." (trailing dot). I18n splits keys on "." and
  # Ruby's String#split drops trailing empty segments, so that key resolves to
  # the *parent* translation node — the entire body_parts Hash — instead of
  # missing-key behavior, and I18n never falls back to `default:`. The caller
  # then renders that Hash's #to_s directly on the page.
  def t_body_part(body_part)
    return "" if body_part.blank?
    key = body_part.to_s.downcase.gsub(" ", "_")
    t("views.exercises.body_parts.#{key}", default: body_part.to_s.capitalize)
  end

  # Translate an equipment value (e.g. "leverage machine") using the i18n locale file.
  def t_equipment(equipment)
    return "" if equipment.blank?
    key = equipment.to_s.downcase.gsub(" ", "_")
    t("views.exercises.equipment.#{key}", default: equipment.to_s.capitalize)
  end

  # Translate a category value (e.g. "strength") using the i18n locale file.
  def t_category(category)
    return "" if category.blank?
    t("views.exercises.categories.#{category.to_s.downcase}", default: category.to_s.capitalize)
  end

  # Translate a muscle name (e.g. "levator scapulae") using the i18n locale file.
  def t_muscle(muscle)
    return "" if muscle.blank?
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
end
