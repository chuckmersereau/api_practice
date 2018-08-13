FactoryBot.define do
  factory :tagging, class: 'ActsAsTaggableOn::Tagging' do
    association :tag
    association :taggable
    context 'test'
  end
end
