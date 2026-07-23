module Exports
  # Resolves the export form's period choice into a Date range, or nil for
  # "no restriction" (dated exporters treat nil as "full history").
  class Period
    KINDS = %w[all last_12_months custom].freeze

    attr_reader :kind, :date_from, :date_to

    def initialize(kind:, date_from: nil, date_to: nil)
      @kind      = KINDS.include?(kind.to_s) ? kind.to_s : "all"
      @date_from = date_from
      @date_to   = date_to
    end

    def range
      case kind
      when "last_12_months" then 12.months.ago.to_date..Date.today
      when "custom"         then custom_range
      else nil
      end
    end

    # Only "custom" can be invalid (missing/reversed dates) — "all" and
    # "last_12_months" are always well-formed since they're computed, not
    # user-entered.
    def valid?
      return true unless kind == "custom"

      date_from.present? && date_to.present? && date_from <= date_to
    end

    private

    def custom_range
      return nil unless date_from.present? && date_to.present? && date_from <= date_to

      date_from..date_to
    end
  end
end
