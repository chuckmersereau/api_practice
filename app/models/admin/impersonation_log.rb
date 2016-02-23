class Admin::ImpersonationLog < ActiveRecord::Base
  belongs_to :impersonator, foreign_key: :impersonator_id, class_name: 'User'
  belongs_to :impersonated, foreign_key: :impersonated_id, class_name: 'User'
end
