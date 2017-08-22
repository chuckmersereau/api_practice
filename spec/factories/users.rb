require 'faker'

FactoryGirl.define do
  factory :user do
    association :master_person
    first_name { Faker::Name.first_name }
    preferences do
      {
        time_zone: Time.zone.name
      }
    end
  end

  factory :user_with_account, parent: :user do
    sequence(:access_token) { |n| "243857230498572349898798#{n}" }
    after :create do |u|
      create(:organization_account, person: u)
      account_list = u.reload.account_lists.first
      create(:relay_account, person: u)
      create(:designation_profile, user: u, account_list: account_list)
    end
  end

  factory :user_with_full_account, parent: :user do
    sequence(:email) { |n| "#{n}#{Faker::Internet.email}" }
    sequence(:access_token) { |n| "1234567890#{n}" }
    time_zone { 'Auckland' }
    locale { 'en' }
    after :create do |u|
      create(:organization_account, person: u)
      account_list = u.reload.account_lists.first
      create(:relay_account, person: u)
      create(:designation_profile, user: u, account_list: account_list)
    end
  end

  factory :admin_user, parent: :user_with_account do
    admin true
  end
end
