FactoryGirl.define do
  factory :admin_impersonation_log, class: 'Admin::ImpersonationLog' do
    association :impersonator
    association :impersonated
    reason 'Test'
  end
end
