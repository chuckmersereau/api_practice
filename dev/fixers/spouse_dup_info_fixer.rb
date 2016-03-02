# This is a script I used to help address this HelpScout ticket:
# https://secure.helpscout.net/conversation/145083350/25821/?folderId=378967
#
# The core issue was that after the user had done a Facebook import, Tnt import,
# and done the Google contacts sync, plus maybe find duplicates at some point.
#
# Somewhere along the way, perhaps due to a bug in MPDX, many of the couples had
# thek same phone number (mobile or work) for both spouses, as well as the same
# emails for both.
#
# What I did before I ran it on production was to create a duplicate of his
# contact data locally and teset it there to make sure it worked correctly.
#
# Similar care should be applied if you use this script again, and some of the
# logic may be specific to his particular issue.
#
# This code may be somewhat specific to that user's particular circumstance and
# may not always apply in every case.

def fix_account_dup_contact_info(account_list, tnt_import)
  tnt_contacts_by_id = find_tnt_contacts_by_id(tnt_import)

  dup_info_contacts = account_list.contacts.select(&method(:people_have_dup_numbers?))
  dup_info_contacts.each do |dup_info_contact|
    fix_dup_info_contact(dup_info_contact, tnt_contacts_by_id)
  end
end

def find_tnt_contacts_by_id(import)
  import.file.cache_stored_file!
  tnt = TntImport.new(import)
  tnt_contacts = tnt.xml['Contact']['row']
  tnt_contacts_by_id = {}
  tnt_contacts.each do |tnt_contact|
    tnt_contacts_by_id[tnt_contact['id'].to_i] = tnt_contact
  end
  tnt_contacts_by_id
end

def people_have_dup_numbers?(contact)
  phones_for_contact = Set.new
  contact.people.each do |person|
    phones = person.phone_numbers.select { |p| p.number.present? }

    numbers = phones.map(&:number)
    existing_matches = phones_for_contact.select do |existing_phone|
      existing_phone.number.in?(numbers)
    end

    existing_numbers = phones_for_contact.map(&:number)
    current_matches = phones.select do |phone|
      phone.number.in?(existing_numbers)
    end

    all_home_numbers = existing_matches.all? { |p| p.location == 'home' } &&
                       current_matches.all? { |p| p.location == 'home' }

    if current_matches.any?
      if all_home_numbers
        puts "Home phones match for contact #{contact} with id #{contact.id}"
      else
        puts "Dup numbers for contact #{contact} with id #{contact.id}"
        return true
      end
    else
      phones.each { |p| phones_for_contact << p }
    end
  end
  false
end

def fix_dup_info_contact(dup_info_contact, tnt_contacts_by_id)
  tnt_fields = tnt_contacts_by_id[dup_info_contact.tnt_id]
  if tnt_fields.blank?
    puts "No Tnt fields for #{dup_info_contact}"
  else
    fix_non_primary_people_info(dup_info_contact, tnt_fields)
  end
end

def fix_non_primary_people_info(dup_info_contact, tnt_fields)
  primary_person = primary_person_by_first_name(dup_info_contact, tnt_fields)
  return unless primary_person

  non_primary_people = dup_info_contact.people.where.not(id: primary_person.id)

  fix_dup_phone(tnt_fields, 'MobilePhone', primary_person, non_primary_people)
  fix_dup_phone(tnt_fields, 'BusinessPhone', primary_person, non_primary_people)
end

def primary_person_by_first_name(dup_info_contact, tnt_fields)
  primary_people = dup_info_contact.people.where(first_name: tnt_fields['FirstName'])
  if primary_people.count > 1
    puts "Tnt primary person not found for #{dup_info_contact}"
    nil
  elsif primary_people.count == 0
    puts "Tnt primary person not found for #{dup_info_contact}"
    nil
  else
    primary_people.first
  end
end

def fix_dup_phone(tnt_fields, tnt_phone_field, primary_person, non_primary_people)
  primary_person_number = tnt_fields[tnt_phone_field]
  return if primary_person_number.blank?

  primary_person_number = clean_number(primary_person_number)

  unless primary_person_number.in?(primary_person.phone_numbers.pluck(:number))
    puts "Primary person #{primary_person} with id #{primary_person.id}"\
      "does not have number #{mobile_phone.number} in MPDX but has it in Tnt"
    return
  end

  non_primary_people.each do |spouse|
    dup_phones = spouse.phone_numbers.where(number: primary_person_number)
    dup_phones.each do |dup_phone|
      puts "Removing number #{dup_phone.number} for person #{spouse} with id #{spouse.id}"
      puts dup_phone.inspect
      dup_phone.destroy
    end
  end
end

def clean_number(number)
  phone = PhoneNumber.new(number: number)
  phone.clean_up_number
  phone.number
end
