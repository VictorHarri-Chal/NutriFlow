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
end
