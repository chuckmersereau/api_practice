class AppealContact < ApplicationRecord
  audited associated_with: :appeal, on: [:destroy]

  belongs_to :appeal, foreign_key: 'appeal_id'
  belongs_to :contact
  validates :appeal, :contact, presence: true
  validates :contact_id, uniqueness: { scope: :appeal_id }
  validate :associations_have_same_account_list

  attr_accessor :force_list_deletion
  validate :contact_on_exclusion_list, if: :contact_on_exclusion_list?
  after_create :remove_from_exclusion_list, if: :contact_on_exclusion_list?

  PERMITTED_ATTRIBUTES = [:overwrite,
                          :contact_id,
                          :updated_at,
                          :updated_in_db_at,
                          :force_list_deletion,
                          :id].freeze

  def destroy_related_excluded_appeal_contact
    Appeal::ExcludedAppealContact.find_by(appeal: appeal, contact: contact)&.destroy
    true
  end

  protected

  def associations_have_same_account_list
    return unless appeal && contact
    return if contact.account_list_id == appeal.account_list_id
    errors[:contact] << 'does not have the same account list as appeal'
  end

  def contact_on_exclusion_list?
    Appeal::ExcludedAppealContact.exists?(appeal: appeal, contact: contact)
  end

  def contact_on_exclusion_list
    return true if ActiveRecord::Type::Boolean.new.type_cast_from_user(force_list_deletion)
    errors[:contact] << 'is on the Excluded List.'
  end

  def remove_from_exclusion_list
    Appeal::ExcludedAppealContact.find_by(appeal: appeal, contact: contact)&.destroy
  end
end
