# This class finds and saves DuplicateRecordPair records by looking through all People in the given AccountList.
# Duplicates are found primarily by comparing the People names, phone numbers, and emails.

class Person::DuplicatePairsFinder < ApplicationDuplicatePairsFinder
  private

  def find_duplicates
    find_duplicates_by_full_name
    find_duplicates_by_first_name
    find_duplicates_by_email
    find_duplicates_by_phone_number
  end

  def people_scope
    account_list.people
  end

  def people_hashes
    @people_hashes ||= build_people_hashes
  end

  def build_people_hashes
    contact_people = ContactPerson.where(person: people_scope).select(:person_id, :contact_id).group_by(&:person_id)
    phone_numbers = PhoneNumber.where(person: people_scope).select(:person_id, :number).group_by(&:person_id)
    email_addresses = EmailAddress.where(person: people_scope).select(:person_id, :email).group_by(&:person_id)

    people_scope.select(:id, :first_name, :last_name, :gender).collect do |person|
      {
        id: person.id,
        contact_ids: contact_people[person.id].collect(&:contact_id),
        first_name: normalize_names([person.first_name]),
        last_name: normalize_names([person.last_name]),
        full_name: normalize_names([person.first_name, person.last_name]),
        email_addresses: normalize_email_addresses(email_addresses[person.id]),
        phone_numbers: normalize_phone_numbers(phone_numbers[person.id]),
        gender: normalize_gender(person.gender)
      }
    end
  end

  def normalize_names(names)
    names = names.collect { |name| name&.squish }
    (names - [nil, '']).sort.join(' ').downcase.gsub(/[^[:word:]]/, ' ').squish
  end

  def normalize_email_addresses(email_addresses)
    return [] unless email_addresses
    email_addresses.collect { |email_address| email_address.email.squish.downcase }
  end

  def normalize_phone_numbers(phone_numbers)
    return [] unless phone_numbers
    phone_numbers.collect { |phone_number| phone_number.number.gsub(/\D/, '') }
  end

  def normalize_gender(gender)
    gender&.split(' ')&.first&.downcase
  end

  def people_hashes_grouped_by_contact_id
    @people_hashes_grouped_by_contact_id ||= group_people_hashes_by_contact_id
  end

  def group_people_hashes_by_contact_id
    people_hashes.each_with_object({}) do |person_hash, people_hashes_grouped_by_contact_id|
      person_hash[:contact_ids].each do |contact_id|
        people_hashes_grouped_by_contact_id[contact_id] ||= []
        people_hashes_grouped_by_contact_id[contact_id] << person_hash
      end
    end
  end

  def find_duplicates_by_full_name
    people_hashes_grouped_by_contact_id.each do |_contact_id, people_hashes|
      find_duplicate_hashes_by_value(people_hashes, :full_name).each do |duplicate_hashes|
        add_duplicate_pair_from_hashes(duplicate_hashes, 'Similar names')
      end
    end
  end

  # If people have the same first name consider them duplicates only if one or both of them are missing a last name.
  def find_duplicates_by_first_name
    people_hashes_grouped_by_contact_id.each do |_contact_id, people_hashes|
      find_duplicate_hashes_by_value(people_hashes, :first_name).each do |duplicate_hashes|
        next unless duplicate_hashes.first[:last_name].blank? || duplicate_hashes.second[:last_name].blank?
        add_duplicate_pair_from_hashes(duplicate_hashes, 'Similar names')
      end
    end
  end

  def find_duplicates_by_email
    people_hashes_grouped_by_contact_id.each do |_contact_id, people_hashes|
      find_duplicate_hashes_by_value(people_hashes, :email_addresses, :values_present_and_intersecting?).each do |duplicate_hashes|
        add_duplicate_pair_from_hashes(duplicate_hashes, 'Similar email addresses')
      end
    end
  end

  def find_duplicates_by_phone_number
    people_hashes_grouped_by_contact_id.each do |_contact_id, people_hashes|
      find_duplicate_hashes_by_value(people_hashes, :phone_numbers, :values_present_and_intersecting?).each do |duplicate_hashes|
        add_duplicate_pair_from_hashes(duplicate_hashes, 'Similar phone numbers')
      end
    end
  end

  # Many couples have the same email or phone number, try to exclude spouses from duplicates by looking at the gender.
  def add_duplicate_pair_from_hashes(duplicate_hashes, reason)
    unless reason.include?('name')
      return if duplicate_hashes.first[:gender] != duplicate_hashes.second[:gender]
      return if duplicate_hashes.first[:gender].blank? && duplicate_hashes.second[:gender].blank?
    end
    super
  end
end
