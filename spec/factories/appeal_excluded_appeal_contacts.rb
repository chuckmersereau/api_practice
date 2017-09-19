FactoryGirl.define do
  factory :appeal_excluded_appeal_contact, class: 'Appeal::ExcludedAppealContact' do
    appeal
    contact do |appeal_excluded_appeal_contact|
      build(:contact, account_list: appeal_excluded_appeal_contact.appeal.account_list)
    end
  end
end
