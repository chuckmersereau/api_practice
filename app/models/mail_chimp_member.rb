class MailChimpMember < ApplicationRecord
  belongs_to :mail_chimp_account
  audited associated_with: :mail_chimp_account

  def email=(email)
    super(email&.downcase)
  end

  def self.mpdx_unsubscribe?(member)
    reason = member.is_a?(Hash) ? member['unsubscribe_reason'] : member
    return false unless reason

    # if MPDX removed the contact from the list it will be something like this
    # we have seen two different values: N/A (Unsubscribed by an admin) and N/A (Unsubscribed by admin)
    (reason =~ %r(N/A \(Unsubscribed by( an)? admin\))).present?
  end
end
