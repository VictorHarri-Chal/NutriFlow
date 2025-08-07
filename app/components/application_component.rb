# frozen_string_literal: true

##
# base class for https://viewcomponent.org/
#
# to generate a new component: https://viewcomponent.org/guide/generators.html
# (by default, sidecar is set to true)
class ApplicationComponent < ViewComponent::Base
  delegate :nested_dom_id,
           :money_with_cents,
           :allowed_to?,
           :modal_with,
           to: :helpers,
           private: true
end
