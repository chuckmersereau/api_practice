class AccountListSerializer < ApplicationSerializer
  attributes :name,
             :default_organization_id,
             :monthly_goal,
             :total_pledges

  has_many :notification_preferences

  def default_organization_id
    object.designation_profiles.first.try(:organization_id) ||
      object.users.first.try(:organization_accounts).try(:first).try(:organization_id)
  end
end
