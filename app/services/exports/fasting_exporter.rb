module Exports
  class FastingExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      headers = ["Date début", "Date fin", "Protocole", "Durée cible (h)", "Durée réelle (h)", "Objectif atteint"]
      rows = scoped_sessions.map do |s|
        [
          s.started_at, s.ended_at, s.protocol.text, s.target_duration_hours,
          s.elapsed_hours.round(1), s.reached_target? ? "Oui" : "Non"
        ]
      end
      [Exports::Sheet.simple(name: "Jeûne intermittent", headers: headers, rows: rows)]
    end

    private

    def scoped_sessions
      scope = @user.fasting_sessions.order(:started_at)
      range = @period&.range
      range ? scope.where(started_at: range.first.beginning_of_day..range.last.end_of_day) : scope
    end
  end
end
