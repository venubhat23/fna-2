# Production fix for password synchronization issue
# This script ensures plain_password is updated when password changes

# Monkey patch the SubAgent model to ensure plain_password is always saved
class SubAgent < ApplicationRecord
  # Override the password= setter to ensure plain_password is updated
  alias_method :original_password_setter, :password=

  def password=(new_password)
    self.plain_password = new_password if new_password.present?
    original_password_setter(new_password)
  end

  # Ensure plain_password is saved on every save
  before_save :ensure_plain_password_updated

  private

  def ensure_plain_password_updated
    if password_digest_changed? && @password.present?
      self.plain_password = @password
      Rails.logger.info "Updated plain_password for SubAgent #{id} to: #{plain_password}"
    end
  end
end

puts "✅ Password synchronization fix applied!"
puts "SubAgents will now properly update plain_password on password changes"