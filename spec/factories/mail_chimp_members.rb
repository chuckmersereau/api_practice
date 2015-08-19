FactoryGirl.define do
  factory :mail_chimp_member do
    email 'john@example.com'
    list_id 'list1'
    status 'Partner - Financial'
    first_name 'John'
    last_name 'Smith'
    greeting 'John'
  end
end
