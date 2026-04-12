module DateParseable
  extend ActiveSupport::Concern

  private

  def parse_date(date_param)
    date_param.present? ? Date.parse(date_param) : Date.current
  rescue ArgumentError, Date::Error
    Date.current
  end
end
