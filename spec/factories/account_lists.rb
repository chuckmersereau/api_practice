# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_list do
    name 'MyString'
    # association :creator, factory: :user
    # association :designation_profile
    designation_accounts { build_list(:designation_account, 1) }
  end
end
