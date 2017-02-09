class AccountListSerializer < ServiceSerializer
  attributes :default_currency,
             :default_organization_id,
             :home_country,
             :monthly_goal,
             :name,
             :tester,
             :total_pledges

  has_many :notification_preferences

  def default_organization_id
    object.designation_profiles.first.try(:organization).try(:uuid) ||
      object.users.first.try(:organization_accounts).try(:first).try(:organization).try(:uuid)
  end
end
