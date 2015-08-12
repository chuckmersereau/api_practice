class MailChimpAppealList < ActiveRecord::Base
  validates :mail_chimp_account, :appeal_list_id, :appeal, presence: true
  belongs_to :mail_chimp_account
  belongs_to :appeal
end
