require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "a profile is auto-created for each user" do
    user = create_user
    assert user.profile.present?
  end

  test "a user cannot have a second profile (DB-3)" do
    user = create_user
    dup  = Profile.new(user: user)
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :user_id
  end
end
