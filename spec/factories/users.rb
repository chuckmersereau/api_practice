# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    association :master_person
    first_name 'John'
    preferences { { setup: false } }
  end

  factory :user_with_account, parent: :user do
    sequence(:access_token) { |n| "243857230498572349898798#{n}" }
    after :create do |u|
      create(:organization_account, person: u)
      account_list = create(:account_list)
      create(:account_list_user, user: u, account_list: account_list)
      create(:relay_account, person: u)
    end
  end

  factory :admin_user, parent: :user_with_account do
    admin true
  end
end
