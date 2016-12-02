# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :website, class: 'Person::Website' do
    url { Faker::Internet.url }
    primary true
    association :person
  end
end
