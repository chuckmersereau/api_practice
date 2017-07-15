class AccountListSerializer < ApplicationSerializer
  attributes :currency,
             :default_currency,
             :home_country,
             :monthly_goal,
             :name,
             :settings,
             :tester,
             :total_pledges

  has_many :notification_preferences

  def settings
    object.settings.merge!(
      salary_organization_id: fetch_salary_organization_uuid
    )
  end

  private

  def fetch_salary_organization_uuid
    return nil unless object.salary_organization_id

    Organization.where(id: object.salary_organization_id)
                .limit(1)
                .pluck(:uuid)
                .first
  end
end
