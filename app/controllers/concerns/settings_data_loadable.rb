module SettingsDataLoadable
  extend ActiveSupport::Concern

  private

  def load_settings_data(active_tab:)
    @active_tab = SettingsController::TABS.key?(active_tab.to_s) ? active_tab.to_s : SettingsController::TABS.keys.first
    @minimum_password_length = User.password_length.min
    # .reset guards against a stale in-memory association target: a failed
    # #create action builds an unsaved (id-less) record via `.build`, which
    # Rails appends to the association's cached target — without resetting,
    # that unsaved record would render in the list and break its edit/delete links.
    current_user.day_food_groups.reset
    current_user.food_labels.reset
    @day_food_groups = current_user.day_food_groups
    @day_food_group ||= DayFoodGroup.new
    @food_labels = current_user.food_labels
    @food_label ||= FoodLabel.new
    # Per-label food counts in one grouped query instead of hydrating every
    # tagged Food into memory just to call .size on the association.
    @food_label_food_counts = current_user.food_labels.joins(:foods).group("food_labels.id").count
    @preference_data_presence = PreferenceDataPresenceLoader.new(current_user).call
    @export_categories = Exports::CategoryRegistry.visible_for(current_user)
  end
end
