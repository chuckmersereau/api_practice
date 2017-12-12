class AppealContact < ApplicationRecord
  audited associated_with: :appeal, on: [:destroy]

  belongs_to :appeal, foreign_key: 'appeal_id'
  belongs_to :contact
  validates :appeal, :contact, presence: true
  validates :contact_id, uniqueness: { scope: :appeal_id }
  validate :associations_have_same_account_list

  PERMITTED_ATTRIBUTES = [:overwrite,
                          :contact_id,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  def destroy_related_excluded_appeal_contact
    Appeal::ExcludedAppealContact.find_by(appeal: appeal, contact: contact).try(:destroy)
    true
  end

  protected

  def associations_have_same_account_list
    return unless appeal && contact
    return if contact.account_list_id == appeal.account_list_id
    errors[:contact] << 'does not have the same account list as appeal'
  end
end
