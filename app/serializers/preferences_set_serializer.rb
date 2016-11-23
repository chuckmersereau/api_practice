class PreferencesSetSerializer < ApplicationSerializer
  attributes :account_list_name,
             :currency,
             :default_account_list,
             :email,
             :first_name,
             :home_country,
             :last_name,
             :locale,
             :ministry_country,
             :monthly_goal,
             :salary_organization_id,
             :tester,
             :time_zone
end
