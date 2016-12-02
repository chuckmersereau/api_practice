FactoryGirl.define do
  factory :appeal_excluded_appeal_contact, class: 'Appeal::ExcludedAppealContact' do
    association :appeal
    association :contact
  end
end
