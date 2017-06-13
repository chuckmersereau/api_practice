class Admin::ResetLog < ApplicationRecord
  belongs_to :admin_resetting, class_name: 'User'
  belongs_to :resetted_user, class_name: 'User'

  validates :resetted_user_id, :admin_resetting_id, :reason, presence: true
end
