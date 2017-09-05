class AccountListSerializer < ApplicationSerializer
  attributes :currency,
             :default_currency,
             :home_country,
             :monthly_goal,
             :name,
             :salary_organization,
             :tester,
             :total_pledges,
             :active_mpd_start_at,
             :active_mpd_finish_at,
             :active_mpd_monthly_goal

  has_many :notification_preferences
  has_many :organization_accounts
  belongs_to :primary_appeal

  def salary_organization
    return nil unless object.salary_organization_id

    Organization.where(id: object.salary_organization_id)
                .limit(1)
                .pluck(:uuid)
                .first
  end
end
