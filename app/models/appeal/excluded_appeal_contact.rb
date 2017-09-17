class Appeal::ExcludedAppealContact < ApplicationRecord
  belongs_to :appeal
  belongs_to :contact
  validates :appeal, :contact, presence: true
  validates :contact_id, uniqueness: { scope: :appeal_id }
  validate :associations_have_same_account_list

  protected

  def associations_have_same_account_list
    return unless appeal && contact
    return if contact.account_list_id == appeal.account_list_id
    errors[:contact] << 'does not have the same account list as appeal'
  end
end
