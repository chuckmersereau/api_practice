FactoryGirl.define do
  factory :mail_chimp_member do
    association :mail_chimp_account

    contact_locale 'en'
    email 'john@example.com'
    first_name 'John'
    greeting 'John'
    last_name 'Smith'
    list_id 'list1'
    status 'Partner - Financial'
  end
end
