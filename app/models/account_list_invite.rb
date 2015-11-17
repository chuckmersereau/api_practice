class AccountListInvite < ActiveRecord::Base
  has_paper_trail on: [:update]

  belongs_to :account_list
  belongs_to :invited_by_user, class_name: 'User'
  belongs_to :accepted_by_user, class_name: 'User'
  belongs_to :cancelled_by_user, class_name: 'User'

  scope :active, -> { where(cancelled_by_user: nil) }

  def accept(accepting_user)
    return false if cancelled?

    # Do nothing, but return true if the same user trys to accept again.
    # If a second user tries to accept an already accepted invite, return false.
    return accepted_by_user == accepting_user if accepted_by_user.present?

    account_list.account_list_users.find_or_create_by(user: accepting_user)
    update(accepted_by_user: accepting_user, accepted_at: Time.now)
  end

  def cancel(canceling_user)
    update(cancelled_by_user: canceling_user)
  end

  def cancelled?
    cancelled_by_user.present?
  end

  def self.send_invite(inviting_user, account_list, email)
    code = SecureRandom.hex(32)
    invite = create(invited_by_user: inviting_user, code: code,
                    recipient_email: email, account_list: account_list)
    AccountListInviteMailer.email(invite).deliver
    invite
  end
end
