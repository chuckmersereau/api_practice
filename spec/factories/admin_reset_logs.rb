FactoryGirl.define do
  factory :admin_reset_log, :class => 'Admin::ResetLog' do
    admin_resetting_id 1
resetted_user_id 1
reason "MyString"
  end

end
