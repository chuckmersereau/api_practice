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
  belongs_to :primary_appeal, serializer: AppealSerializer

  def salary_organization
    object.salary_organization_id
  end
end
