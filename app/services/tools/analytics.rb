class Tools::Analytics < ActiveModelSerializers::Model
  include ActiveModel::Validations

  validates :account_lists, presence: true

  attr_accessor :account_lists

  def initialize(attributes = {})
    super

    after_initialize
  end

  def counts_by_type
    account_lists.map do |account_list|
      {
        id: account_list.uuid,
        counts: counts_by_type_for_account_list(account_list)
      }
    end
  end

  private

  def counts_by_type_for_account_list(account_list)
    [
      { type: 'fix-commitment-info', count: fix_commitment_info_count(account_list) },
      { type: 'fix-phone-numbers', count: fix_phone_number_count(account_list) },
      { type: 'fix-email-addresses', count: fix_email_addresses_count(account_list) },
      { type: 'fix-addresses', count: fix_addresses_count(account_list) },
      { type: 'duplicate-contacts', count: duplicate_contacts_count(account_list) },
      { type: 'duplicate-people', count: duplicate_people_count(account_list) }
    ]
  end

  def fix_commitment_info_count(account_list)
    account_list.contacts.where(status_valid: false).count
  end

  def fix_phone_number_count(account_list)
    Person::Filter::PhoneNumberValid.query(account_list.people, { phone_number_valid: 'false' }, account_list).count
  end

  def fix_email_addresses_count(account_list)
    Person::Filter::EmailAddressValid.query(account_list.people, { email_address_valid: 'false' }, account_list).count
  end

  def fix_addresses_count(account_list)
    Contact::Filter::AddressValid.query(account_list.contacts, { address_valid: 'false' }, account_list).count
  end

  def duplicate_contacts_count(account_list)
    Contact::DuplicatesFinder.new(account_list).find.count
  end

  def duplicate_people_count(account_list)
    Person::DuplicatesFinder.new(account_list).find.count
  end

  def after_initialize
    raise ArgumentError, errors.full_messages.join(', ') if invalid?
  end
end
