# frozen_string_literal: true

module DayScoped
  def find_day_scoped(klass, id)
    klass.joins(:day).where(days: { user_id: current_user.id }).find(id)
  end
end
