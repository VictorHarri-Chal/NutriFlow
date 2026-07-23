module Exports
  class BodyMeasurementsExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      headers = [
        "Date", "Tour de taille (cm)", "Tour de hanches (cm)", "Tour de poitrine (cm)",
        "Tour de biceps (cm)", "Tour de cuisses (cm)", "Tour de mollets (cm)", "Tour de cou (cm)",
        "Ratio taille/hanches", "Ratio taille/taille", "% Masse grasse estimé"
      ]
      rows = scoped_measurements.map do |m|
        [
          m.date, m.waist_cm, m.hips_cm, m.chest_cm, m.biceps_cm, m.thighs_cm, m.calves_cm, m.neck_cm,
          m.waist_hip_ratio, m.waist_height_ratio, m.estimated_body_fat_percentage
        ]
      end
      [Exports::Sheet.simple(name: "Mesures corporelles", headers: headers, rows: rows)]
    end

    private

    def scoped_measurements
      scope = @user.body_measurements.ordered
      range = @period&.range
      range ? scope.where(date: range) : scope
    end
  end
end
