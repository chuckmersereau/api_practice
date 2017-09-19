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
      { type: 'fix-send-newsletter', count: fix_send_newsletter_count(account_list) },
      { type: 'duplicate-contacts', count: duplicate_contacts_count(account_list) },
      { type: 'duplicate-people', count: duplicate_people_count(account_list) }
    ]
  end

  def filter_contacts(account_list, filter_params)
    Contact::Filterer.new(filter_params).filter(scope: account_list.contacts, account_lists: [account_list])
  end

  def filter_people(account_list, filter_params)
    person_scope = Person.joins(:contact_people).where(contact_people: { contact: account_list.contacts })
    Person::Filterer.new(filter_params).filter(scope: person_scope, account_lists: [account_list])
  end

  def fix_commitment_info_count(account_list)
    filter_contacts(account_list, status_valid: 'false').count
  end

  def fix_phone_number_count(account_list)
    filter_people(account_list, phone_number_valid: 'false').count
  end

  def fix_email_addresses_count(account_list)
    filter_people(account_list, email_address_valid: 'false').count
  end

  def fix_addresses_count(account_list)
    filter_contacts(account_list, address_valid: 'false').count
  end

  def fix_send_newsletter_count(account_list)
    filter_contacts(account_list,
                    newsletter: 'no_value',
                    status: 'Partner - Financial,Partner - Special,Partner - Pray').count
  end

  def duplicate_contacts_count(account_list)
    Contact::DuplicatePairsFinder.new(account_list).find_and_save
    DuplicateRecordPair.type('Contact').where(account_list: account_list, ignore: false).count
  end

  def duplicate_people_count(account_list)
    Person::DuplicatePairsFinder.new(account_list).find_and_save
    DuplicateRecordPair.type('Person').where(account_list: account_list, ignore: false).count
  end

  def after_initialize
    raise ArgumentError, errors.full_messages.join(', ') if invalid?
  end
end
