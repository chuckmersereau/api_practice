FactoryBot.define do
  factory :website, class: 'Person::Website' do
    association :person
    url { Faker::Internet.url }
    primary true
  end
end
