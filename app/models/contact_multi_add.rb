class ContactMultiAdd
  def initialize(account_list, referring_contact = nil)
    @account_list = account_list
    @referring_contact = referring_contact
  end

  def add_contacts(contacts_attributes)
    contacts = Contact.transaction do
      contacts_attributes.values
                         .select { |attrs| attrs.values.any?(&:present?) }
                         .map(&method(:create_contact_and_people))
    end
    [contacts.compact, contacts.count(&:nil?)]
  end

  private

  def create_contact_and_people(attrs)
    return unless attrs[:first_name].present? || attrs[:last_name].present?
    contact = create_contact(attrs)
    add_primary_person(contact, attrs)
    add_spouse(contact, attrs) if attrs[:spouse_first_name].present?
    add_address(contact, attrs)
    @referring_contact.referrals_by_me << contact if @referring_contact
    contact
  rescue ActiveRecord::RecordInvalid
  end

  def create_contact(attrs)
    attrs[:first_name] = _('Unknown') if attrs[:first_name].blank?
    attrs[:last_name] = _('Unknown') if attrs[:last_name].blank?
    contact_name = "#{attrs[:last_name]}, #{attrs[:first_name]}"
    contact_name += " & #{attrs[:spouse_first_name]}" if attrs[:spouse_first_name].present?
    contact_greeting = (attrs[:first_name]).to_s
    contact_greeting += " & #{attrs[:spouse_first_name]}" if attrs[:spouse_first_name].present?
    contact = @account_list.contacts.create(name: contact_name, greeting: contact_greeting,
                                            notes: attrs[:notes])
    contact
  end

  def add_primary_person(contact, attrs)
    person = Person.create(attrs.slice(:first_name, :last_name, :email, :phone))
    contact.people << person
  end

  def add_spouse(contact, attrs)
    spouse = Person.create(first_name: attrs[:spouse_first_name], last_name: attrs[:last_name],
                           phone: attrs[:spouse_phone], email: attrs[:spouse_email])
    contact.people << spouse
  end

  def add_address(contact, attrs)
    contact.addresses_attributes = [
      attrs.slice(:street, :city, :state, :postal_code).merge(primary_mailing_address: true)
    ]
    contact.save
  end
end
