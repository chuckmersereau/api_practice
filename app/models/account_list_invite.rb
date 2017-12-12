class AccountListInvite < ApplicationRecord
  audited associated_with: :account_list

  belongs_to :account_list
  belongs_to :invited_by_user, class_name: 'User'
  belongs_to :accepted_by_user, class_name: 'User'
  belongs_to :cancelled_by_user, class_name: 'User'

  scope :active, -> { where(cancelled_by_user: nil, accepted_by_user: nil) }

  validates :recipient_email, presence: true
  validates :invite_user_as, inclusion: { in: %w(user coach) }

  PERMITTED_ATTRIBUTES = [:created_at,
                          :overwrite,
                          :recipient_email,
                          :invite_user_as,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  def accept(accepting_user)
    return false if cancelled?

    # Do nothing, but return true if the same user trys to accept again.
    # If a second user tries to accept an already accepted invite, return false.
    return accepted_by_user == accepting_user if accepted_by_user.present?

    if invite_user_as == 'coach'
      account_list.account_list_coaches.find_or_create_by(coach: accepting_user.becomes(User::Coach))
    else
      account_list.account_list_users.find_or_create_by(user: accepting_user)
    end

    update(accepted_by_user: accepting_user, accepted_at: Time.now)
  end

  def cancel(canceling_user)
    update(cancelled_by_user: canceling_user)
  end

  def cancelled?
    cancelled_by_user.present?
  end

  def self.send_invite(inviting_user, account_list, email, invite_user_as)
    code = SecureRandom.hex(32)
    invite = create(invited_by_user: inviting_user,
                    invite_user_as: invite_user_as,
                    code: code,
                    recipient_email: email,
                    account_list: account_list)
    AccountListInviteMailer.delay.email(invite)
    invite
  end
end
