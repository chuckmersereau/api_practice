class AccountListSerializer < ApplicationSerializer
  attributes :currency,
             :default_currency,
             :home_country,
             :monthly_goal,
             :name,
             :tester,
             :total_pledges

  has_many :notification_preferences
end
