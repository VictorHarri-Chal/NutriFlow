# frozen_string_literal: true

class PreferenceToggleComponent < ApplicationComponent
  def initialize(field:, checked:, url:, has_existing_data: false)
    @field = field
    @checked = checked
    @url = url
    @has_existing_data = has_existing_data
  end

  private

  attr_reader :field, :checked, :url, :has_existing_data

  def input_id
    "user_#{field}"
  end

  def field_name
    "user[#{field}]"
  end

  def label_key
    "views.settings.preferences.#{field}"
  end

  def hint_key
    "#{label_key}_hint"
  end

  def requires_confirmation?
    has_existing_data && checked
  end

  def confirm_message
    t("views.settings.preferences.confirm_disable", feature: t(label_key))
  end

  def confirm_params
    { field_name => "0" }.to_json
  end
end
