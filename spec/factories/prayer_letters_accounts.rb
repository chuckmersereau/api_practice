FactoryBot.define do
  factory :prayer_letters_account do
    token 'MyString'
    oauth2_token 'MyString'
    valid_token true
    association :account_list
  end

  factory :prayer_letters_account_oauth2, class: PrayerLettersAccount do
    oauth2_token 'test_oauth2_token'
    valid_token true
    association :account_list
  end
end
