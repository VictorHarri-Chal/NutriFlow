# frozen_string_literal: true

class AlertComponent < ApplicationComponent
  attr_reader :title, :description, :level

  TITLE_LEVEL_CLASSES = {
    info: "text-macro-calories",
    warning: "text-status-warning",
    alert: "text-status-danger"
  }.freeze

  DESCRIPTION_LEVEL_CLASSES = {
    info: "text-macro-calories/80",
    warning: "text-status-warning/80",
    alert: "text-status-danger/80"
  }.freeze

  BACKGROUND_LEVEL_CLASSES = {
    info: "bg-status-info_dim/20 border border-status-info/30 rounded-lg",
    warning: "bg-status-warning_dim/20 border border-status-warning/30 rounded-lg",
    alert: "bg-status-danger_dim/20 border border-status-danger/30 rounded-lg"
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
