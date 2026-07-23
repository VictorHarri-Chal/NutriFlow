module Exports
  class CardioExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      headers = ["Date", "Machine", "Durée (min)", "Vitesse (km/h)", "Inclinaison (%)", "Résistance", "Distance (km)", "Calories brûlées"]
      rows = scoped_blocks.map do |block|
        [
          block.cardio_session.day.date,
          I18n.t("views.cardio_sessions.machines.#{block.machine}"),
          block.duration_minutes,
          block.speed_kmh,
          block.incline_percent,
          block.resistance_level,
          block.distance_km,
          block.calories_burned
        ]
      end
      [Exports::Sheet.simple(name: "Cardio", headers: headers, rows: rows)]
    end

    private

    def scoped_blocks
      scope = CardioBlock.joins(cardio_session: :day)
                         .where(days: { user_id: @user.id })
                         .includes(cardio_session: :day)
                         .order("days.date")
      range = @period&.range
      range ? scope.where(days: { date: range }) : scope
    end
  end
end
