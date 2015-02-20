module TntImportUtil
  # This is an ordered array of the Tnt phone types. The order matters because the tnt  PreferredPhoneType
  # is an index that into this list and the PhoneIsValidMask is a bit vector that refers to these in order too.
  TNT_PHONES = [
    { field: 'HomePhone', location: 'home', person: :both }, # index 0
    { field: 'HomePhone2', location: 'home', person: :both },
    { field: 'HomeFax', location: 'fax', person: :both },
    { field: 'OtherPhone', location: 'other', person: :both },
    { field: 'OtherFax', location: 'fax', person: :both },

    { field: 'MobilePhone', location: 'mobile', person: :primary },
    { field: 'MobilePhone2', location: 'mobile', person: :primary },
    { field: 'PagerNumber', location: 'other', person: :primary },
    { field: 'BusinessPhone', location: 'work', person: :primary },
    { field: 'BusinessPhone2', location: 'work', person: :primary },
    { field: 'BusinessFax', location: 'fax', person: :primary },
    { field: 'CompanyMainPhone', location: 'work', person: :primary },

    { field: 'SpouseMobilePhone', location: 'mobile', person: :spouse },
    { field: 'SpouseMobilePhone2', location: 'mobile', person: :spouse },
    { field: 'SpousePagerNumber', location: 'other', person: :spouse },
    { field: 'SpouseBusinessPhone', location: 'work', person: :spouse },
    { field: 'SpouseBusinessPhone2', location: 'work', person: :spouse },
    { field: 'SpouseBusinessFax', location: 'fax', person: :spouse },
    { field: 'SpouseCompanyMainPhone', location: 'work', person: :spouse } # index 18
  ]

  def read_xml(import_file)
    xml = {}
    begin
      File.open(import_file, 'r:utf-8') do |file|
        @contents = file.read
        begin
          xml = Hash.from_xml(@contents)
        rescue => e
          # If the document contains characters that we don't know how to parse
          # just strip them out.
          # The eval is dirty, but it was all I could come up with at the time
          # to unescape a unicode character.
          begin
            bad_char = e.message.match(/"([^"]*)"/)[1]
            @contents.gsub!(eval(%("#{bad_char}")), ' ') # rubocop:disable Eval
          rescue
            raise e
          end
          retry
        end
      end
    rescue ArgumentError
      File.open(import_file, 'r:windows-1251:utf-8') do |file|
        xml = Hash.from_xml(file.read)
      end
    end
    xml
  end

  def lookup_mpd_phase(phase)
    case phase.to_i
    when 10 then 'Never Contacted'
    when 20 then 'Ask in Future'
    when 30 then 'Contact for Appointment'
    when 40 then 'Appointment Scheduled'
    when 50 then 'Call for Decision'
    when 60 then 'Partner - Financial'
    when 70 then 'Partner - Special'
    when 80 then 'Partner - Pray'
    when 90 then 'Not Interested'
    when 95 then 'Unresponsive'
    when 100 then 'Never Ask'
    when 110 then 'Research Abandoned'
    when 130 then 'Expired Referral'
    end
  end

  def lookup_task_type(task_type_id)
    case task_type_id.to_i
    when 1 then 'Appointment'
    when 2 then 'Thank'
    when 3 then 'To Do'
    when 20 then 'Call'
    when 30 then 'Reminder Letter'
    when 40 then 'Support Letter'
    when 50 then 'Letter'
    when 60 then 'Newsletter'
    when 70 then 'Pre Call Letter'
    when 100 then 'Email'
    end
  end

  def lookup_history_result(history_result_id)
    case history_result_id.to_i
    when 1 then 'Done'
    when 2 then 'Received'
    when 3 then 'Attempted'
    end
  end

  def true?(val)
    val.upcase == 'TRUE'
  end

  def parse_date(val)
    Date.parse(val)
  rescue
  end

  # TntMPD allows multiple emails to be marked as preferred and expresses that array of booleans as a
  # bit vector in the PreferredEmailTypes. Bit 0 is ignored, then 3 for primary person emails, then 3 for spouse
  def tnt_email_preferred?(row, email_num, person_prefix)
    preferred_bit_index = (person_prefix == 'Spouse' ? 3 : 0) + email_num
    row['PreferredEmailTypes'].present? && row['PreferredEmailTypes'].to_i[preferred_bit_index] == 1
  end

  def update_person_attributes(person, row, prefix = '')
    person.attributes = { first_name: row[prefix + 'FirstName'], last_name: row[prefix + 'LastName'], middle_name: row[prefix + 'MiddleName'],
                          title: row[prefix + 'Title'], suffix: row[prefix + 'Suffix'], gender: prefix.present? ? 'female' : 'male',
                          profession: prefix.present? ? nil : row['Profession'] }

    update_person_phones(person, row, prefix)
    update_person_emails(person, row, prefix)
    person
  end

  def update_person_phones(person, row, prefix)
    person_sym = prefix == '' ? :primary : :spouse
    is_valid_mask = row['PhoneIsValidMask'].to_i # Bit vector indexed corresponding to TNT_PHONES
    had_no_primary = person.phone_numbers.where(primary: true).empty?

    TNT_PHONES.each_with_index do |tnt_phone, i|
      number = row[tnt_phone[:field]]
      next unless number.present? && (tnt_phone[:person] == :both || tnt_phone[:person] == person_sym)

      phone_attrs =  { number: number, location: tnt_phone[:location], historic: is_valid_mask[i] == 0 }
      if (@import.override? || had_no_primary) && row['PreferredPhoneType'].to_i == i
        phone_attrs[:primary] = true
        person.phone_numbers.each { |phone| phone.update(primary: false) }
      end
      person.phone_number =  phone_attrs
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
      if (@import.override? || had_no_primary) && !changed_primary && !historic && tnt_email_preferred?(row, i, prefix)
        person.email_addresses.each { |e| e.update(primary: false) }
        email_attrs[:primary] = true
        changed_primary = true
      end

      person.email_address = email_attrs
    end
  end
end
