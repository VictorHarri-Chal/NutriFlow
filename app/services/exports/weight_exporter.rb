module Exports
  class WeightExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      headers = ["Date", "Poids (kg)"]
      rows = scoped_entries.map { |e| [e.date, e.weight_kg] }
      [Exports::Sheet.simple(name: "Poids", headers: headers, rows: rows)]
    end

    private

    def scoped_entries
      scope = @user.weight_entries.ordered
      range = @period&.range
      range ? scope.where(date: range) : scope
    end
  end
end
