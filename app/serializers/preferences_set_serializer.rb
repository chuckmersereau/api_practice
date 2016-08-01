class PreferencesSetSerializer < ActiveModel::Serializer
  attributes :first_name, :last_name, :email, :time_zone, :locale, :monthly_goal, :default_account_list, :tester,
             :home_country, :ministry_country, :currency, :salary_organization_id, :account_list_name 
end
