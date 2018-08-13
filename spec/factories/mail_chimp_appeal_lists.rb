FactoryBot.define do
  factory :mail_chimp_appeal_list do
    association :mail_chimp_account
    association :appeal
    sequence(:appeal_list_id) { |n| n }
  end
end
