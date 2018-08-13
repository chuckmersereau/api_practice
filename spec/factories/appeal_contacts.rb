FactoryBot.define do
  factory :appeal_contact do
    appeal
    contact do |appeal_contact|
      build(:contact, account_list: appeal_contact.appeal.account_list)
    end
  end
end
