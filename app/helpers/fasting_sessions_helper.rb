module FastingSessionsHelper
  def format_fasting_duration(hours)
    total_minutes = (hours * 60).round
    h = total_minutes / 60
    m = total_minutes % 60
    format("%dh%02d", h, m)
  end

  def format_fasting_clock(time)
    time.strftime("%H:%M")
  end

  # Every protocol targets under 24h, so the expected end is never more than
  # one calendar day after "now" — a same-day/tomorrow check is sufficient,
  # no need for a generic date format.
  def fasting_ends_tomorrow?(session)
    session.expected_end_at.to_date != Date.current
  end

  def fasting_expected_end_label(session)
    key = fasting_ends_tomorrow?(session) ? :expected_end_tomorrow : :expected_end
    t("views.calendars.fasting.#{key}", time: format_fasting_clock(session.expected_end_at))
  end
end
