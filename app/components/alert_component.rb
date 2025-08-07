# frozen_string_literal: true

class AlertComponent < ApplicationComponent
  attr_reader :title, :description, :level

  TITLE_LEVEL_CLASSES = {
    info: "text-blue-800",
    warning: "text-yellow-800",
    alert: "text-red-800"
  }.freeze

  DESCRIPTION_LEVEL_CLASSES = {
    info: "text-blue-700",
    warning: "text-yellow-700",
    alert: "text-red-700"
  }.freeze

  BACKGROUND_LEVEL_CLASSES = {
    info: "bg-blue-50",
    warning: "bg-yellow-50",
    alert: "bg-red-50"
  }.freeze

  def initialize(title:, level:, description: nil)
    super
    @title = title
    @description = description
    @level = level.to_sym
  end

  def title_level_class
    TITLE_LEVEL_CLASSES[level]
  end

  def description_level_class
    DESCRIPTION_LEVEL_CLASSES[level]
  end

  def background_level_class
    BACKGROUND_LEVEL_CLASSES[level]
  end

  def icon
    case level
    when :info
      "info-circle"
    when :warning
      "triangle-exclamation"
    when :alert
      "circle-exclamation"
    end
  end
end
