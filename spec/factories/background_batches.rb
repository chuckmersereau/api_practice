FactoryGirl.define do
  factory :background_batch do
    batch_id 'MyString'
    user
    after :build do |background_batch|
      background_batch.requests << build(:background_batch_request, background_batch: nil)
    end
  end
end
