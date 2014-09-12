class GoogleContactsIntegrator
  attr_accessor :client

  def initialize(google_integration)
    @google_integration = google_integration
    @account = google_integration.google_account
  end

  def sync_contacts
    @google_integration.account_list.active_contacts.each { |contact| sync_contact(contact) }
  end

  def sync_contact(contact)
    contact.people.each { |person| sync_person(person, contact) }
  end

  def sync_person(person, contact)
    g_contact_record = person.google_contacts.find_by_google_account_id(@account.id)
    if g_contact_record
      g_contact = @account.contacts_api_user.get_contact(g_contact_record.remote_id)
    else
      g_contact = query_g_contact(person, contact)
    end

    if g_contact.nil?
      g_contact = create_g_contact(person, contact)
    else
      sync_with_g_contact(person, contact, g_contact_record, g_contact)
    end

    g_contact_record ||= person.google_contacts.build(remote_id: g_contact.id, google_account: @account)
    g_contact_record.last_etag = g_contact.etag
    g_contact_record.last_synced = Time.now
    g_contact_record.save
  end

  def query_g_contact(person, contact)
    @account.contacts_api_user.query_contacts(person.first_name + ' ' + person.last_name).find do |g_contact|
      g_contact.given_name == person.first_name && g_contact.family_name == person.last_name
    end
  end

  def sync_with_g_contact(person, contact, g_contact_record, g_contact, override = true, import_from_google = true)
    return if g_contact_record && g_contact_record.last_etag == g_contact.etag # already in sync

    sync_basic_person_fields(g_contact, person, import_from_google, override)
    sync_contact_fields(g_contact, contact, import_from_google, override)
    sync_employer_and_title(g_contact, person, import_from_google, override)

    # sync_phone_numbers(g_contact, g_contact_record, person, import_from_google, override)

    # For array lists, like phone numbers, emails, addresses, websites:
    # If already associated with the contact && override => Favor MPDX completely

    g_contact.send_update
    person.save
    contact.save
  end

  def sync_phone_numbers(g_contact, g_contact_record, person, import_from_google, override)
    # There's a tension between:
    # 1. added data, like a new number in Google or a new number in MPDX
    # 2. updated or fixed data, like a changed number in Google or MPDX
    # 3. what about a deleted phone number?
    # The system can't easily tell the difference between the two.
    # What if we stored a JSON representation of the Google Contact as of last sync?


    # Step 1: MPDX changes from previous sync
    # Step 2: Google changes from previous sync

    # Step 3: Combine the changes



    # Adds to both sides
    # Updates to both, if conflict, preserve both numbers in both

    # Deletions ?? Possible the person just didn't want a particular number in MPDX or in Google. Even if the docs
    # tell them something they might not follow it and could lose information
    # On the other hand, if something really is an old number, would be good to allow them to get rid of it.
  end

  def mpdx_changes_since_sync(g_contact_record, person)
    changes = []

    mpdx_g_number_map = g_contact_record.last_sync_map[:phone_numbers]
    person_number_ids = []
    person.phone_numbers.each do |number|
      if mpdx_g_number_map.has_key?(number.id)
        old_number = g_contact_record.last_sync_data[:phone_numbers].find {|n| n[:number] ==  mpdx_g_number_map[id] }
        new_number = format_phone_for_google(number)
        changes << [:update, number.id, mpdx_g_number_map[id], new_number] unless old_number == new_number
      else
        changes << [:create, number.id, format_phone_for_google(number) ]
      end
      person_number_ids << number.id
    end

    person_number_ids.each do |id|
      unless mpdx_g_number_map.has_key?(id)
        changes << [:delete, mpdx_g_number_map[id]]
      end
    end

    changes
  end

  def google_changes_since_sync(g_contact_record, g_contact)
    # Probably run an alignment algorithm over the two arrays of numbers
    # http://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
  end

  def sync_employer_and_title(g_contact, person, import_from_google, override)
    person_orgs = g_contact_organizations_for(person)
    g_contact_orgs = g_contact.organizations
    if g_contact_orgs.size > 0
      if person_orgs.size > 0
        g_contact.prep_update(organizations: person_orgs) if override
      else
        # The Google Contacts GUI only lets you edit a single organization, so we'll assume we can pull from the first
        first_org = g_contact_orgs.first
        person.update(employer: first_org.org_name, occupation: first_org.org_title) if import_from_google
      end
    else
      g_contact.prep_update(organizations: person_orgs) if person_orgs.size > 0
    end
  end

  def sync_contact_fields(g_contact, contact, import_from_google, override)
    sync_g_contact_and_record({ notes: :content }, g_contact, contact, import_from_google, override)
  end

  def sync_basic_person_fields(g_contact, person, import_from_google, override)
    person_to_g_contact_fields = {
      title: :name_prefix,
      first_name: :given_name,
      middle_name: :additional_name,
      last_name: :family_name,
      suffix: :name_suffix
    }
    sync_g_contact_and_record(person_to_g_contact_fields, g_contact, person, import_from_google, override)
  end

  def sync_g_contact_and_record(field_map, g_contact, record, import_from_google, override)
    field_map.each do |record_field, g_contact_field|
      if g_contact.send(g_contact_field).present?
        if record[record_field].present?
          g_contact.prep_update(g_contact_field => record.send(record_field)) if override
        else
          record.update(record_field => g_contact.send(g_contact_field)) if import_from_google
        end
      else
        g_contact.prep_update(g_contact_field => record.send(record_field)) if record.send(record_field).present?
      end
    end
  end

  def create_g_contact(person, contact)
    @account.contacts_api_user.create_contact(
      name_prefix: person.title,
      given_name: person.first_name,
      additional_name: person.middle_name,
      family_name: person.last_name,
      name_suffix: person.suffix,
      content: contact.notes,
      emails: person.email_addresses.map(&method(:format_email_for_google)),
      phone_numbers: person.phone_numbers.map(&method(:format_phone_for_google)),
      organizations: g_contact_organizations_for(person),
      websites: person.websites.map(&method(:format_website_for_google)),
      addresses: contact.addresses.map(&method(:format_address_for_google))
    )
  end

  def g_contact_organizations_for(person)
    if person.employer.present? || person.occupation.present?
      [ { org_name: person.employer, org_title: person.occupation, primary: true } ]
    else
      []
    end
  end

  def format_email_for_google(email)
    { address: email.email, primary: email.primary, rel: email.location.in?(%w(work home)) ? email.location : 'other' }
  end

  def format_phone_for_google(phone)
    # From https://developers.google.com/gdata/docs/2.0/elements#gdPhoneNumber
    allowed_rels = %w(assistant callback car company_main fax home home_fax isdn main mobile other other_fax pager radio telex tty_tdd work work_fax work_mobile work_pager)
    { number: phone.number, primary: phone.primary, rel: phone.location.in?(allowed_rels) ? phone.location : 'other' }
  end

  def format_website_for_google(website)
    { href: website.url, primary: website.primary, rel: 'other' }
  end

  def format_address_for_google(address)
    { rel: address_location_to_rel(address.location), primary: address.primary_mailing_address,
      street: address.street, city: address.city, region: address.state, postcode: address.postal_code,
      country: address.country == 'United States' ? 'United States of America' : address.country }
  end

  def address_location_to_rel(location)
    if location == 'Business'
      'work'
    elsif location == 'Home'
      'home'
    else
      'other'
    end
  end
end
