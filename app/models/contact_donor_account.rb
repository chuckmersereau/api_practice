class ContactDonorAccount < ApplicationRecord
  belongs_to :contact, inverse_of: :contact_donor_accounts
  belongs_to :donor_account, inverse_of: :contact_donor_accounts

  validate :ensure_one_contact_per_donor_account_number

  audited associated_with: :contact

  def ensure_one_contact_per_donor_account_number
    if contact.account_list.donor_accounts.where(account_number: donor_account.account_number).any?
      contact.errors.add(:base, _("Another contact on your account already has the donor account number you've tried to assign to this contact."))
      false
    end
    # Organization either doesn't sync automatically or doesn't support donors with same ID
    if contact.account_list.designation_accounts.empty? && donor_account.organization.donor_accounts.where(account_number: donor_account.account_number).any?
      contact.errors.add(:base, _("Another contact in your organization already has the donor account number you've tried to assign to this contact.  Please make it more unique."))
      false
    end
    true
  end
end
