class AccountListSerializer < BaseSerializer
  attributes :id, :name, :created_at, :updated_at, :monthly_goal, :total_pledges, :default_organization_id

  def default_organization_id
    object.designation_profiles.first.try(:organization_id) || object.users.first.try(:organization_accounts).try(:first).try(:organization_id)
  end
end
