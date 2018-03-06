class MailChimpMember < ApplicationRecord
  belongs_to :mail_chimp_account

  def email=(email)
    super(email&.downcase)
  end
end
