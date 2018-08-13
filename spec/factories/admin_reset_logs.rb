FactoryBot.define do
  factory :admin_reset_log, class: 'Admin::ResetLog' do
    admin_resetting_id { SecureRandom.uuid }
    resetted_user_id { SecureRandom.uuid }
    reason 'MyString'
  end
end
