Warden::Manager.after_set_user except: :fetch do |user, warden, options|
  next unless user.is_a?(User)
  next if user.sign_in_count.to_i <= 1
  next if user.last_sign_in_ip.blank? || user.current_sign_in_ip.blank?
  next if user.last_sign_in_ip == user.current_sign_in_ip

  Users::DeviseMailer.new_device_sign_in(user, user.current_sign_in_ip).deliver_later
end
