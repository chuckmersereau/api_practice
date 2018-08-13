FactoryBot.define do
  factory :picture do
    image nil
    association :picture_of
  end
end
