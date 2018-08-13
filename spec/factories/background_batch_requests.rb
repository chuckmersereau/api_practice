FactoryBot.define do
  factory :background_batch_request, class: 'BackgroundBatch::Request' do
    background_batch
    path 'api/v2/user'
  end
end
