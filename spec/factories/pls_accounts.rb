FactoryBot.define do
  factory :pls_account do
    association :account_list
    oauth2_token 'MyString'
  end
end
