class Admin::Impersonation
  include ActiveModel::Model
  attr_accessor :reason, :impersonator, :user_finder, :impersonation_logger,
                :impersonate_lookup
  attr_reader :impersonated

  validates :reason, presence: true
  validate :exactly_one_user_found

  def save
    @found_users = user_finder.find_users(impersonate_lookup)
    return false unless valid?
    @impersonated = @found_users.first
    impersonation_logger.create!(
      impersonator: impersonator, impersonated: @impersonated, reason: reason)
    true
  end

  private

  def exactly_one_user_found
    if @found_users.count == 0
      errors.add(:base, _('No users found for that lookup'))
    elsif @found_users.count > 1
      errors.add(:base, _('More than one user found for that lookup'))
    end
  end
end
