class Admin::ResetLogPolicy < ApplicationPolicy
  def create?
    resource.valid? &&
      resource_owner? &&
      user_is_admin? &&
      resource.resetted_user.present? &&
      !expired? &&
      !completed?
  end

  private

  def resource_owner?
    user == resource.admin_resetting
  end

  def user_is_admin?
    user.admin == true
  end

  def expired?
    (resource.created_at || Time.current) < 1.day.ago
  end

  def completed?
    resource.completed_at.present?
  end
end
