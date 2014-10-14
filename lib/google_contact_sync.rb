module GoogleContactSync
  def sync_with_g_contact(person, g_contact, g_contact_link)
    sync_basic_person_fields(person, g_contact, g_contact_link)
    sync_employer_and_title(person, g_contact, g_contact_link)
    sync_emails(g_contact, person, g_contact_link)
    sync_numbers(g_contact, person, g_contact_link)
    sync_websites(g_contact, person, g_contact_link)
  end

  def sync_notes(contact, g_contact, g_contact_link)
    sync_g_contact_and_record(contact, g_contact, g_contact_link, notes: :content)
  end

  def sync_basic_person_fields(person, g_contact, g_contact_link)
    sync_g_contact_and_record(person, g_contact, g_contact_link, title: :name_prefix, first_name: :given_name,
                              middle_name: :additional_name, last_name: :family_name, suffix: :name_suffix)
  end

  def sync_g_contact_and_record(record, g_contact, g_contact_link, field_map)
    field_map.each do |field, g_contact_field|
      synced_value = compare_field_for_sync(record[field], g_contact.send(g_contact_field),
                                            g_contact_link.last_data[g_contact_field])

      # Replace vertical tabs with newlines in both MPDX and Google Contact as vertical tabs are invalid XML and
      # will get escaped to newlines by  the google_contacts_api gem.
      # By fixing them in MPDX as well, we make the values the same to simplify future syncs.
      synced_value.gsub!("\v", "\n") if synced_value

      g_contact.prep_changes(g_contact_field => synced_value) if synced_value != g_contact.send(g_contact_field)
      record[field] = synced_value
    end
  end

  def sync_employer_and_title(person, g_contact, g_contact_link)
    g_contact_orgs = g_contact.organizations
    last_orgs = g_contact_link.last_data[:organizations] || []

    # Since in the Google Contacts user interface you can only set the title and org name for a
    # single organization it's a reasonable assumption to just look at the first organization
    employer = compare_field_for_sync(person.employer, field_of_first(g_contact_orgs, :org_name),
                                      field_of_first(last_orgs, :org_name))
    occupation = compare_field_for_sync(person.occupation, field_of_first(g_contact_orgs, :org_title),
                                        field_of_first(last_orgs, :org_title))

    person.update(employer: employer, occupation: occupation)

    if field_of_first(g_contact_orgs, :org_name) != employer || field_of_first(g_contact_orgs, :org_title) != occupation
      g_contact.prep_changes(organizations: g_contact_organizations_for(employer, occupation))
    end
  end

  def compare_field_for_sync(mpdx_val, g_contact_val, last_val)
    mpdx_changed = mpdx_val != last_val && (mpdx_val.present? || last_val.present?)

    if mpdx_changed
      # If MPDX changed, the synced value is the MPDX "wins" if both MPDX and Google were changed
      mpdx_val
    else
      # Otherwise the synced value should be the Google value in case it changed.
      g_contact_val
    end
  end

  def field_of_first(hashes, field)
    hashes.empty? ? nil : hashes.first[field]
  end

  def sync_emails(g_contact, person, g_contact_link)
    mpdx_adds, mpdx_dels, g_contact_adds, g_contact_dels = compare_emails_for_sync(g_contact, person, g_contact_link)

    add_emails_from_g_contact(mpdx_adds, g_contact, person)
    mpdx_dels.each { |email| person.email_addresses.where(email: email).destroy_all }

    g_contact_emails = g_contact.emails_full
    g_contact_primary = g_contact_emails.find { |email| email[:primary] }
    g_contact_emails += g_contact_adds.map { |email|
      email_attrs = format_email_for_google(person.email_addresses.find_by_email(email))
      email_attrs[:primary] = false if g_contact_primary
      email_attrs
    }
    g_contact_emails.delete_if { |email| g_contact_dels.include?(email[:address]) }
    g_contact.prep_changes(emails: g_contact_emails)
  end

  def sync_numbers(g_contact, person, g_contact_link)
    mpdx_adds, mpdx_dels, g_contact_adds, g_contact_dels = compare_numbers_for_sync(g_contact, person, g_contact_link)

    add_numbers_from_g_contact(mpdx_adds, g_contact, person)
    mpdx_dels.each { |number| person.phone_numbers.where(number: number).destroy_all }

    g_contact_numbers = g_contact.phone_numbers_full
    g_contact_primary = g_contact_numbers.find { |number| number[:primary] }
    g_contact_numbers += g_contact_adds.map { |number|
      number_attrs = format_phone_for_google(person.phone_numbers.find_by_number(number))
      number_attrs[:primary] = false if g_contact_primary
      number_attrs
    }
    g_contact_numbers.delete_if { |number| g_contact_dels.include?(normalize_number(number[:number])) }
    g_contact.prep_changes(phone_numbers: g_contact_numbers)
  end

  def sync_addresses(g_contacts, contact, g_contact_links)
    g_contact_addresses = g_contacts.flat_map(&:addresses).to_set

    last_addresses = g_contact_links.flat_map { |g_contact_link| g_contact_link.last_data[:addresses] }.to_set

    mpdx_adds, mpdx_dels, g_contact_adds, g_contact_dels, g_contact_address_records =
      compare_addresses_for_sync(g_contact_addresses, contact, last_addresses)

    # Add and delete MPDX address records
    add_addresses_from_g_contact(mpdx_adds, contact)
    mpdx_dels.destroy_all

    # Build the Google Contact address list and assign it to all Google contacts
    g_contact_address_records = remove_duplicate_addresses(g_contact_address_records) + g_contact_adds

    g_contact_address_records.delete_if { |address| g_contact_dels.include?(address.master_address_id) }
    ensure_single_primary_address(g_contact_address_records)
    g_contact_addresses = g_contact_address_records.map { |address| format_address_for_google(address) }
    g_contacts.each { |g_contact| g_contact.prep_changes(addresses: g_contact_addresses.to_a) }
  end

  def sync_websites(g_contact, person, g_contact_link)
    mpdx_adds, mpdx_dels, g_contact_adds, g_contact_dels = compare_websites_for_sync(g_contact, person, g_contact_link)

    add_websites_from_g_contact(mpdx_adds, g_contact, person)
    mpdx_dels.each { |url| person.websites.where(url: url).destroy_all }

    g_contact_websites = g_contact.websites
    g_contact_primary = g_contact_websites.find { |website| website[:primary] }
    g_contact_websites += g_contact_adds.map { |url|
      website = { href: url, rel: 'other' }
      website[:primary] = false if g_contact_primary
      website
    }
    g_contact_websites.delete_if { |website| g_contact_dels.include?(website[:href]) }
    g_contact.prep_changes(websites: g_contact_websites)
  end

  def remove_duplicate_addresses(addresses)
    addresses.map(&:master_address_id).to_set.map { |master_address_id|
      lookup_by_key(addresses, master_address_id: master_address_id)
    }
  end

  def ensure_single_primary_address(addresses)
    found_primary = false
    addresses.each do |address|
      next unless address.primary_mailing_address
      if found_primary
        address.primary_mailing_address = false
      else
        found_primary = true
      end
    end
  end

  def add_addresses_from_g_contact(addresses, contact)
    contact_primary = contact.addresses.where(primary_mailing_address: true)
    addresses.each do |address|
      address.primary_mailing_address = false if contact_primary
      contact.addresses << address
    end
  end

  def add_emails_from_g_contact(emails_to_add, g_contact, person)
    had_primary = person.primary_email_address.present?

    g_contact_emails = g_contact.emails_full
    emails_to_add.each do |email|
      email_address = format_email_for_mpdx(lookup_by_key(g_contact_emails, address: email))
      email_address[:primary] = false if had_primary
      person.email_address = email_address
    end
  end

  def add_numbers_from_g_contact(numbers_to_add, g_contact, person)
    had_primary = person.primary_phone_number.present?

    g_contact_numbers_normalized_map = Hash[g_contact.phone_numbers_full.map { |number|
      [normalize_number(number[:number]), number]
    }]

    numbers_to_add.each do |number|
      number_attrs = format_phone_for_mpdx(g_contact_numbers_normalized_map[number])
      number_attrs[:primary] = false if had_primary
      person.phone_number = number_attrs
    end
  end

  def add_websites_from_g_contact(urls_to_add, g_contact, person)
    had_primary = person.websites.where(primary: true).first
    g_contact_websites = g_contact.websites

    urls_to_add.each do |url|
      g_contact_website = lookup_by_key(g_contact_websites, href: url)
      website = Person::Website.new(url: url, primary: g_contact_website[:primary])
      website[:primary] = false if had_primary
      person.websites << website
    end
  end

  def compare_websites_for_sync(g_contact, person, g_contact_link)
    last_sync_websites = g_contact_link.last_data[:websites].map { |websites| websites[:href] }
    compare_for_sync(last_sync_websites, person.websites.pluck(:url), g_contact.websites.map { |w| w[:href] })
  end

  def compare_emails_for_sync(g_contact, person, g_contact_link)
    last_sync_emails = g_contact_link.last_data[:emails].map { |email| email[:address] }
    compare_considering_historic(last_sync_emails, person.email_addresses.where(historic: false).pluck(:email),
                                 g_contact.emails, person.email_addresses.where(historic: true).pluck(:email))
  end

  def compare_numbers_for_sync(g_contact, person, g_contact_link)
    last_sync_numbers = g_contact_link.last_data[:phone_numbers].map { |p| p[:number] }
    compare_normalized_for_sync(last_sync_numbers, person.phone_numbers.map(&:number), g_contact.phone_numbers,
                                method(:normalize_number))
  end

  def compare_addresses_for_sync(g_contact_addresses, contact, last_addresses)
    compare_address_records(g_contact_addresses.map(&method(:new_address_for_g_address)), contact,
                            last_addresses.map(&method(:new_address_for_g_address)))
  end

  def compare_address_records(g_contact_address_records, contact, last_address_records)
    # Compare normalized addresses (by master_address_id)
    mpdx_adds, mpdx_dels, g_contact_adds, g_contact_dels =
      compare_normalized_for_sync(last_address_records, contact.addresses.where(historic: false),
                                  g_contact_address_records, method(:normalize_address),
                                  contact.addresses.where(historic: true))

    # Convert from the master_address_id back to entries in addresses lists
    # (except for g_contact_dels)
    [
      mpdx_adds.map { |master_id| lookup_by_key(g_contact_address_records, master_address_id: master_id) },
      contact.addresses.where(master_address_id: mpdx_dels.to_a),
      contact.addresses.where(master_address_id: g_contact_adds.to_a),
      g_contact_dels,
      g_contact_address_records
    ]
  end

  def normalize_number(number)
    global = GlobalPhone.parse(number)
    global ? global.international_string : number
  end

  def new_address_for_g_address(g_addr)
    Address.new(street: g_addr[:street], city: g_addr[:city], state: g_addr[:region], postal_code: g_addr[:postcode],
                country: g_addr[:country] == 'United States of America' ? 'United States' : g_addr[:country],
                location: address_rel_to_location(g_addr[:rel]), primary_mailing_address: g_addr[:primary])
  end

  def normalize_address(address)
    address.find_or_create_master_address unless address.master_address_id
    fail "No master_address_id for address: #{address}" unless address.master_address_id
    address.master_address_id
  end

  def compare_normalized_for_sync(last_sync_list, mpdx_list, g_contact_list, normalize_fn, historic_list = [])
    compare_considering_historic(last_sync_list.map(&normalize_fn), mpdx_list.map(&normalize_fn),
                                 g_contact_list.map(&normalize_fn), historic_list.map(&normalize_fn))
  end

  def compare_considering_historic(last_sync_list, mpdx_list, g_contact_list, historic_list)
    historic = historic_list.to_set
    mpdx_adds, mpdx_dels, g_contact_adds, g_contact_dels =
      compare_for_sync(last_sync_list, mpdx_list, g_contact_list)

    # Don't add/delete MPDX's historic items, don't add them to Google,
    # but do delete them from Google
    [mpdx_adds - historic, mpdx_dels - historic, g_contact_adds - historic,
     g_contact_dels + historic]
  end

  def compare_for_sync(last_sync_list, mpdx_list, g_contact_list)
    last_sync_set = last_sync_list.to_set
    mpdx_set = mpdx_list.to_set
    g_contact_set = g_contact_list.to_set

    # These sets represent what MPDX and Google Contacts added or deleted since the last sync
    mpdx_added = mpdx_set - last_sync_set
    g_contact_added = g_contact_set - last_sync_set
    mpdx_deleleted = last_sync_set - mpdx_set
    g_contact_deleleted = last_sync_set - g_contact_set

    # These sets represent what MPDX and Google Contacts need to add or delete to get in sync again
    # Basically, you just propgate the added/deleted entries from one to the other, but we also
    # subtract out the entries that system already added or deleted on its own.
    #
    # An update simply becomes an add and a delete and both are propagated.
    # Thus a conflicting update will result in both systems preserving the two new values and
    # deleting the old value. This preserves the user's intention across systems and allows them to
    # then delete the incorrect conflicted value (or just keep both if they're both correct).
    mpdx_to_add = g_contact_added - mpdx_added
    g_contact_to_add = mpdx_added - g_contact_added
    mpdx_to_delete = g_contact_deleleted - mpdx_deleleted
    g_contact_to_delete = mpdx_deleleted - g_contact_deleleted

    [mpdx_to_add, mpdx_to_delete, g_contact_to_add, g_contact_to_delete]
  end

  def lookup_by_key(hashes_list, search_key_value)
    key = search_key_value.keys[0]
    value = search_key_value.values[0]
    hashes_list.find { |hash| hash[key] == value }
  end

  def g_contact_organizations_for(employer, occupation)
    if employer.present? || occupation.present?
      [{ org_name: employer, org_title: occupation, primary: true, rel: 'work' }]
    else
      []
    end
  end

  def format_email_for_mpdx(email)
    { email: email[:address], primary: email[:primary], location: email[:rel] }
  end

  def format_email_for_google(email)
    { primary: email.primary, rel: email.location.in?(%w(work home)) ? email.location : 'other', address: email.email }
  end

  def format_phone_for_mpdx(phone)
    { number: phone[:number], location: phone[:rel] }
  end

  def format_phone_for_google(phone)
    number = phone.number
    global = GlobalPhone.parse(number)
    if global
      number = global.country_code == '1' ? global.national_format : global.international_format
    end

    # From https://developers.google.com/gdata/docs/2.0/elements#gdPhoneNumber
    allowed_rels = %w(assistant callback car company_main fax home home_fax isdn main mobile other other_fax pager radio telex tty_tdd work work_fax work_mobile work_pager)
    { number: number, primary: phone.primary, rel: phone.location.in?(allowed_rels) ? phone.location : 'other' }
  end

  def format_website_for_google(website)
    { href: website.url, primary: website.primary, rel: 'other' }
  end

  def format_address_for_google(address)
    { rel: address_location_to_rel(address.location), primary: address.primary_mailing_address, street: address.street,
      city: address.city, region: address.state, postcode: address.postal_code,
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

  def address_rel_to_location(rel)
    if rel == 'work'
      'Business'
    elsif rel == 'home'
      'Home'
    else
      'Other'
    end
  end
end
