require "aws-sdk-s3"

module BodyMeasurementsHelper
  # Illustrative adult circumference orders of magnitude (cm) — placeholder
  # text only, not clinical targets. "other"/unset gender falls back to the
  # mean of male/female, mirroring Profile#gender_bmr_constant's convention.
  TYPICAL_MEASUREMENTS_CM = {
    waist_cm:  { male: 90, female: 80 },
    hips_cm:   { male: 100, female: 100 },
    chest_cm:  { male: 100, female: 90 },
    biceps_cm: { male: 33, female: 28 },
    thighs_cm: { male: 55, female: 56 },
    calves_cm: { male: 38, female: 35 },
    neck_cm:   { male: 38, female: 33 }
  }.freeze

  def measurement_placeholder(field, user)
    values = TYPICAL_MEASUREMENTS_CM[field]

    case user.profile&.gender.to_s
    when "male"   then values[:male]
    when "female" then values[:female]
    else               ((values[:male] + values[:female]) / 2.0).round
    end
  end

  # Plain-text summary of the measurements logged on an entry, used in the
  # photo modal (e.g. "Taille 88,0 cm · Hanches 88,0 cm").
  def measurement_summary_text(entry)
    BodyMeasurement::MEASUREMENT_FIELDS.filter_map do |field|
      value = entry.public_send(field)
      next unless value.present?

      "#{t("views.weight_entries.measurements.fields_short.#{field}")} #{value} cm"
    end.join(" · ")
  end

  # Returns the display image URL via direct CDN URL (bypasses the Rails
  # redirect controller). Returns nil if no photo is attached, the blob is
  # missing from storage (e.g. manually deleted from R2), or the active
  # storage service can't generate a URL (e.g. local Disk service in
  # development/test without ActiveStorage::Current.url_options set).
  def body_measurement_image_url(body_measurement, variant: nil)
    return unless body_measurement.image.attached?

    if variant
      body_measurement.image.variant(variant).processed.url
    else
      body_measurement.image.url
    end
  rescue ActiveStorage::Error, ArgumentError, Aws::S3::Errors::ServiceError
    nil
  end
end
