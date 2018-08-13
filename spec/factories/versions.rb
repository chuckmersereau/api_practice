FactoryBot.define do
  factory :version do
    association :item
    association :related_object
    event 'event'
    whodunnit ':)'
    object nil
  end
end
