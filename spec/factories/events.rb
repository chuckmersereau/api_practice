FactoryGirl.define do
  factory :event do
    association :account_list
    starred false
    location 'MyString'
    subject 'MyString'
    start_at '2012-03-08 14:59:46'
    end_at '2012-03-08 14:59:46'
  end
end
