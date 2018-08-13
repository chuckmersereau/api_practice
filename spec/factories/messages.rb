FactoryBot.define do
  factory :message do
    subject 'MyString'
    body 'MyText'
    sent_at '2013-07-10 08:19:52'
    source 'MyString'
    remote_id 'MyString'
    association :account_list
  end
end
