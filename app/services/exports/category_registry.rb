module Exports
  # Single source of truth for every exportable category: which exporter
  # builds it, whether it respects the period filter, which section it's
  # grouped under in the UI, and which user preference toggle (if any) must
  # be on for it to even be offered. The settings view and ExportsController
  # both read from here — never two lists to keep in sync.
  class CategoryRegistry
    SECTIONS = %i[profile journal_nutrition training body_tracking wellbeing summary].freeze

    CATEGORIES = [
      { key: "profile",            section: :profile,           exporter: ProfileExporter,           dated: false, guard: nil },
      { key: "journal",            section: :journal_nutrition, exporter: JournalExporter,            dated: true,  guard: nil },
      { key: "foods",              section: :journal_nutrition, exporter: FoodsExporter,              dated: false, guard: nil },
      { key: "recipes",            section: :journal_nutrition, exporter: RecipesExporter,            dated: false, guard: nil },
      { key: "strength_training",  section: :training,          exporter: StrengthTrainingExporter,   dated: true,  guard: ->(user) { user.show_workout_section? } },
      { key: "cardio",             section: :training,          exporter: CardioExporter,             dated: true,  guard: ->(user) { user.show_cardio_section? } },
      { key: "workout_programs",   section: :training,          exporter: WorkoutProgramsExporter,    dated: false, guard: nil },
      { key: "weight",             section: :body_tracking,     exporter: WeightExporter,             dated: true,  guard: ->(user) { user.show_weight_tracking? } },
      { key: "body_measurements",  section: :body_tracking,     exporter: BodyMeasurementsExporter,   dated: true,  guard: ->(user) { user.show_body_measurements? } },
      { key: "fasting",            section: :wellbeing,         exporter: FastingExporter,            dated: true,  guard: ->(user) { user.show_fasting_tracking? } },
      { key: "nutrition_summary",  section: :summary,           exporter: NutritionSummaryExporter,   dated: true,  guard: nil },
      { key: "training_summary",   section: :summary,           exporter: TrainingSummaryExporter,    dated: true,  guard: ->(user) { user.show_workout_section? || user.show_cardio_section? } },
      { key: "wellbeing_summary",  section: :summary,           exporter: WellbeingSummaryExporter,   dated: true,  guard: ->(user) { user.show_day_note? || user.show_water_tracking? } },
    ].freeze

    def self.visible_for(user)
      CATEGORIES.select { |c| c[:guard].nil? || c[:guard].call(user) }
    end
  end
end
