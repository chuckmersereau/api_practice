class Admin::ResetLog < ActiveRecord::Base
  belongs_to :admin_resetting, class_name: 'User'
  belongs_to :resetted_user, class_name: 'User'
end
