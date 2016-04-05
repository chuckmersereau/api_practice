class GoogleImport
  def initialize(import)
    @user = import.user
    @import = import
    @account_list = import.account_list
  end

  def import
    return false unless @import.source_account_id

    google_account = @user.google_accounts.find(@import.source_account_id)
    begin
      google_account.update_column(:downloading, true)
      import_contacts(google_account)
      google_account.update_column(:last_download, Time.now)
    ensure
      google_account.update_column(:downloading, false)
    end
  end

  def import_contacts(google_account)
    if @import.import_by_group?
      @import.groups.each do |group_id|
        import_contacts_batch(google_account.contacts_for_group(group_id),
                              @import.tags + ',' + @import.group_tags[group_id])
      end
    else
      import_contacts_batch(google_account.contacts, @import.tags)
    end
  rescue Person::GoogleAccount::MissingRefreshToken
    # This triggers an "import failed" email to the user but won't log the error in Rollbar
    raise Import::UnsurprisingImportError
  end

  def import_contacts_batch(google_contacts, tags)
    google_contacts.each do |g_contact|
      begin
        import_contact(g_contact, tags)
      rescue => e
        Rollbar.raise_or_notify(e)
        next
      end
    end
  end

  def import_contact(g_contact, tags)
    return unless g_contact.given_name

    person = create_or_update_person(g_contact)
    contact = create_or_update_contact(person, g_contact, tags)
    spouse = create_spouse_if_specified(contact, person, g_contact)

    contact.people.reload

    begin
      contact.people << person unless contact.people.include?(person)
      contact.people << spouse unless spouse.nil? || contact.people.include?(spouse)
    rescue ActiveRecord::RecordNotUnique
    end
  end

  def create_or_update_contact(person, g_contact, tags)
    contact = @account_list.contacts.with_person(person).first

    unless contact
      name = "#{person.last_name}, #{person.first_name}"
      contact = @account_list.contacts.find_or_create_by(name: name)
    end

    contact.notes = g_contact.content if @import.override? || contact.notes.blank?
    contact.addresses_attributes = build_addresses(contact, g_contact)
    contact.tag_list.add(tags, parse: true) if tags.present?
    contact.save
    contact
  end

  def build_addresses(contact, g_contact)
    mpdx_had_no_primary = contact.addresses.where(primary_mailing_address: true).empty?

    addresses = g_contact.addresses.map do |g_contact_address|
      address_attrs = format_address_for_mpdx(g_contact_address)

      if address_attrs[:primary_mailing_address] && (@import.override? || mpdx_had_no_primary)
        contact.addresses.each { |non_primary| non_primary.update(primary_mailing_address: false) }
      else
        address_attrs[:primary_mailing_address] = false
      end

      address_attrs
    end
    ensure_one_primary(addresses, :primary_mailing_address) if mpdx_had_no_primary

    addresses
  end

  def ensure_one_primary(items, primary_attribute = :primary)
    found_primary = false
    items.each do |item|
      if found_primary
        item[primary_attribute] = false
      else
        found_primary = item[primary_attribute]
      end
    end
    items[0][primary_attribute] = true if !items.empty? && !found_primary
  end

  def format_address_for_mpdx(google_address)
    { street:  google_address[:street], city: google_address[:city], state: google_address[:region],
      postal_code: google_address[:postcode],
      country: format_g_contact_country(google_address[:country]),
      location: google_address_rel_to_location(google_address[:rel]),
      primary_mailing_address: google_address[:primary],
      source: 'GoogleImport' }
  end

  def format_g_contact_country(country)
    if country == 'United States of America'
      'United States'
    elsif country.nil? || country.is_a?(String)
      country
    else
      raise "Unexpected country from Google Contacts import: #{country}"
    end
  end

  def google_address_rel_to_location(rel)
    if rel == 'work'
      'Business'
    elsif rel == 'home'
      'Home'
    else
      'Other'
    end
  end

  def create_spouse_if_specified(contact, person, g_contact)
    spouse = g_contact.spouse
    return if spouse.blank?

    # This regexp makes the first name be all the words up to the last word, and the last name be the
    # last word, so it can catch cases like, "Mary", "Mary Smith" and "Mary Beth Smith".
    first, last = spouse.split(/\s+(?=\S*+$)/)

    # Assume same last names if none specified for spouse
    last ||= person.last_name

    return unless contact.people.where(first_name: first, last_name: last).empty?

    name = if person.last_name == last
             "#{person.last_name}, #{person.first_name} and #{first}"
           else
             "#{person.last_name}, #{person.first_name} and #{first} (#{last})"
           end
    contact.update(name: name)

    Person.create!(first_name: first, last_name: last)
  end

  def create_or_update_person(g_contact)
    person = create_or_update_person_basic_info(g_contact)

    update_person_emails(person, g_contact)
    update_person_phones(person, g_contact)
    update_person_websites(person, g_contact)

    google_contact = person.google_contacts.create_with(google_account_id: @import.source_account_id)
                           .find_or_create_by(remote_id: g_contact.id)
    update_person_picture(person, google_contact, g_contact)

    person.save
    person
  end

  def create_or_update_person_basic_info(g_contact)
    person = (@account_list.people.includes(:google_contacts).find_by('google_contacts.remote_id' => g_contact.id) ||
              @account_list.people.find_by(first_name: g_contact.given_name, last_name: g_contact.family_name))

    person_attrs = person_attr_from_g_contact(g_contact)

    if person
      person.update(person_attrs.select { |k, v| v.present? && (@import.override? || person.send(k).blank?) })
      person
    else
      Person.create!(person_attrs)
    end
  end

  def person_attr_from_g_contact(g_contact)
    attrs = {
      title: g_contact.name_prefix,
      first_name: g_contact.given_name,
      middle_name: g_contact.additional_name,
      last_name: g_contact.family_name,
      suffix: g_contact.name_suffix,
      birthday_day: g_contact.birthday ? g_contact.birthday[:day] : nil,
      birthday_month: g_contact.birthday ? g_contact.birthday[:month] : nil,
      birthday_year: g_contact.birthday ? g_contact.birthday[:year] : nil
    }

    # The Google Contacts Web UI seems to only let you add a single organization for a contact, so let's just
    # take the first one or the one that's primary and save that to the person's employer and occupation.
    unless g_contact.organizations.empty?
      primary_org = g_contact.organizations.first
      g_contact.organizations.each { |org| primary_org = org if org[:primary] }
      attrs[:occupation] = primary_org[:org_title]
      attrs[:employer] = primary_org[:org_name]
    end

    attrs
  end

  def update_person_emails(person, g_contact)
    num_emails_before_import = person.email_addresses.count
    g_contact.emails_full.each do |import_email|
      email = { email: import_email[:address], location: import_email[:rel] }
      if import_email[:primary] && (@import.override? || num_emails_before_import == 0)
        person.email_addresses.update_all primary: false
        email[:primary] = true
      end
      person.email_address = email
    end
  end

  def update_person_phones(person, g_contact)
    num_phones_before_import = person.phone_numbers.count
    g_contact.phone_numbers_full.each do |import_phone|
      phone = { number: import_phone[:number], location: import_phone[:rel] }
      if import_phone[:primary] && (@import.override? || num_phones_before_import == 0)
        person.phone_numbers.update_all primary: false
        phone[:primary] = true
      end
      person.phone_number = phone
    end
  end

  def update_person_websites(person, g_contact)
    num_websites_before_import = person.websites.count
    at_least_one_primary = num_websites_before_import > 0
    g_contact.websites.each_with_index do |import_website, index|
      next if import_website[:href].in? person.websites.pluck(:url)

      if import_website[:primary] && (@import.override? || num_websites_before_import == 0)
        person.websites.update_all primary: false
        import_website[:primary] = true
        at_least_one_primary = true
      elsif !at_least_one_primary && index == g_contact.websites.length - 1
        import_website[:primary] = true
      else
        import_website[:primary] = false
      end

      person.websites << Person::Website.new(url: import_website[:href], primary: import_website[:primary])
    end
  end

  def update_person_picture(person, google_contact, g_contact_to_import)
    # Don't update the picture of people who have a connected facebook account as that will provide their picture
    return if person.facebook_account

    photo = g_contact_to_import.photo_with_metadata
    return if photo.nil? || google_contact.picture_etag == photo[:etag]

    primary = person.pictures.count == 0 || @import.override?
    person.pictures.update_all(primary: false) if primary

    image_io = StringIOWithPath.new(photo[:etag] + image_mime_to_extension(photo[:content_type]), photo[:data])
    picture = Picture.create(image: image_io, primary: primary)
    google_contact.update(picture_etag: photo[:etag], picture_id: picture.id)
    person.pictures << picture
  end

  def image_mime_to_extension(mime)
    '.' + mime.gsub('image/', '')
  end
end
