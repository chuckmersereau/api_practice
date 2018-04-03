class TntImport::PersonImport
  include YearCompletable

  def initialize(row, contact, prefix, override)
    @row = row
    @contact = contact
    @prefix = prefix
    @override = override
  end

  def import
    add_or_update_person(@row, @contact, @prefix)
  end

  private

  def add_or_update_person(row, contact, prefix = '')
    row[prefix + 'FirstName'] = 'Unknown' if row[prefix + 'FirstName'].blank?

    # See if there's already a person by this name on this contact (This is a contact with multiple donation accounts)
    person = contact.people.where(first_name: row[prefix + 'FirstName'], last_name: row[prefix + 'LastName'])
                    .find_by("middle_name = ? OR middle_name = '' OR middle_name is NULL", row[prefix + 'MiddleName'])
    person ||= Person.new

    update_person_attributes(person, row, prefix)

    person.master_person_id ||= MasterPerson.find_or_create_for_person(person).id

    person.save(validate: false)

    begin
      contact.people << person unless contact.people.include?(person)
    rescue ActiveRecord::RecordNotUnique
    end

    person
  end

  def update_person_attributes(person, row, prefix = '')
    new_attributes = { first_name: row[prefix + 'FirstName'], last_name: row[prefix + 'LastName'],
                       middle_name: row[prefix + 'MiddleName'],
                       title: row[prefix + 'Title'], suffix: row[prefix + 'Suffix'],
                       gender: prefix.present? ? 'female' : 'male',
                       occupation: row[prefix + 'Profession'],
                       employer: row[prefix + 'BusinessName'],
                       birthday_month: row[prefix + 'BirthdayMonth'],
                       birthday_day: row[prefix + 'BirthdayDay'],
                       birthday_year: get_four_digit_year_from_value(row[prefix + 'BirthdayYear']),
                       anniversary_month: row[prefix + 'AnniversaryMonth'],
                       anniversary_day: row[prefix + 'AnniversaryDay'],
                       anniversary_year: get_four_digit_year_from_value(row[prefix + 'AnniversaryYear']),
                       deceased: (row['Deceased'] == 'true') }

    person.attributes = if !person.persisted?
                          new_attributes
                        elsif @override
                          person.attributes.symbolize_keys.merge(new_attributes)
                        else
                          new_attributes.merge(person.attributes.symbolize_keys)
                        end

    update_person_phones(person, row, prefix)
    update_person_emails(person, row, prefix)
    update_person_social_media_accounts(person, row, prefix)
    update_contact_primary_person(person, prefix)
    person
  end

  def update_person_phones(person, row, prefix)
    person_sym = prefix == '' ? :primary : :spouse
    is_valid_mask = row['PhoneIsValidMask'].to_i # Bit vector indexed corresponding to TNT_PHONES
    had_no_primary = person.phone_numbers.where(primary: true).empty?

    TntImport::TntCodes::TNT_PHONES.each_with_index do |tnt_phone, i|
      number = row[tnt_phone[:field]]
      next unless number.present? && (tnt_phone[:person] == :both || tnt_phone[:person] == person_sym)

      phone_attrs = { number: number, location: tnt_phone[:location], historic: (is_valid_mask[i]).zero? }
      if (@override || had_no_primary) && row['PreferredPhoneType'].to_i == i
        phone_attrs[:primary] = true
        person.phone_numbers.each { |phone| phone.update(primary: false) }
      end
      person.phone_number = phone_attrs
    end
  end

  def update_person_emails(person, row, prefix)
    changed_primary = false
    had_no_primary = person.email_addresses.where(primary: true).empty?

    # If there is just a single email in Tnt, it leaves the suffix off, so start with a blank then do the numbers
    # up to three as Tnt allows a maximum of 3 email addresses for a person/spouse.
    (1..3).each do |i|
      email = row[prefix + "Email#{i}"]
      next unless email.present?

      email_valid = row["#{prefix}Email#{i}IsValid"]
      historic = email_valid.present? && !true?(email_valid)

      email_attrs = { email: email, historic: historic }

      # For MPDX, we set the primary email to be the first "preferred" email listed in Tnt.
      if (@override || had_no_primary) && !changed_primary && !historic && tnt_email_preferred?(row, i, prefix)
        person.email_addresses.each { |e| e.update(primary: false) }
        email_attrs[:primary] = true
        changed_primary = true
      end

      EmailAddress.expand_and_clean_emails(email_attrs).each do |cleaned_attrs|
        person.email_address = cleaned_attrs
      end
    end
  end

  def update_person_social_media_accounts(person, row, prefix)
    import_social_column(person.facebook_accounts, row, prefix, 'SocialWeb1', :username)
    import_social_column(person.linkedin_accounts, row, prefix, 'SocialWeb2', :public_url)
    import_social_column(person.twitter_accounts, row, prefix, 'SocialWeb3', :screen_name)
    import_social_column(person.websites, row, prefix, 'WebPage1', :url)
    import_social_column(person.websites, row, prefix, 'WebPage2', :url)
  end

  def import_social_column(relationship, row, prefix, col_name, remote_field)
    remote_value = row["#{prefix}#{col_name}"]
    new_account = relationship.find_or_initialize_by(remote_field => remote_value) if remote_value

    # if the record is invalid, don't try to initialize it
    relationship.delete(new_account) if new_account&.invalid?
  end

  def true?(val)
    val.casecmp('TRUE').zero?
  end

  # TntMPD allows multiple emails to be marked as preferred and expresses that array of booleans as a
  # bit vector in the PreferredEmailTypes. Bit 0 is ignored, then 3 for primary person emails, then 3 for spouse
  def tnt_email_preferred?(row, email_num, person_prefix)
    preferred_bit_index = (person_prefix == 'Spouse' ? 3 : 0) + email_num
    row['PreferredEmailTypes'].present? && row['PreferredEmailTypes'].to_i[preferred_bit_index] == 1
  end

  def update_contact_primary_person(person, prefix)
    @contact.primary_person_id = person.id if @override && prefix == ''
  end
end
