# This class finds and saves DuplicateRecordPair records by looking through all Contacts in the given AccountList.
# Duplicates are found primarily by comparing the Contact names and DonorAccount numbers.

class Contact::DuplicatePairsFinder
  attr_reader :account_list, :duplicate_ids, :duplicate_record_pairs

  def initialize(account_list)
    @account_list = account_list
    @duplicate_ids = Set.new
    @duplicate_record_pairs = []
  end

  def find_and_save
    find_duplicates_by_name
    find_duplicates_by_donor_number
    duplicate_record_pairs.select(&:save)
  end

  private

  def contacts_scope
    account_list.contacts
  end

  def contact_names_hashes
    @contact_names_hashes ||= build_hashes_for_comparing_contact_names
  end

  def build_hashes_for_comparing_contact_names
    contacts_scope.pluck(:id, :name).collect do |contact_id_and_name|
      contact_id = contact_id_and_name[0]
      original_name = contact_id_and_name[1]
      parsed_name = HumanNameParser.new(original_name).parse
      primary_name = Contact::NameBuilder.new(parsed_name.slice(:first_name, :last_name)).name

      {
        contact_id: contact_id,
        original_name: original_name.squish,
        rebuilt_name: Contact::NameBuilder.new(original_name).name,
        primary_name: primary_name,
        spouse_or_primary_name: Contact::NameBuilder.new(parsed_name.slice(:spouse_first_name, :spouse_last_name)).name.presence || primary_name
      }
    end
  end

  def find_duplicates_by_name
    find_duplicates_by_original_name
    find_duplicates_by_rebuilt_name
    find_duplicates_by_primary_name
    find_duplicates_by_spouse_or_primary_name
  end

  def find_duplicates_by_original_name
    find_duplicate_hashes_by_value(contact_names_hashes, :original_name).each do |duplicate_hashes|
      add_duplicate(duplicate_hashes.first[:contact_id], duplicate_hashes.second[:contact_id], 'Similar names')
    end
  end

  # We rebuild the name so that we can compare a consistent format of the name.
  # e.g. "John H. Doe" and "Doe, John" should be considered duplicates.
  def find_duplicates_by_rebuilt_name
    find_duplicate_hashes_by_value(contact_names_hashes, :rebuilt_name).each do |duplicate_hashes|
      add_duplicate(duplicate_hashes.first[:contact_id], duplicate_hashes.second[:contact_id], 'Similar names')
    end
  end

  # Find duplicates where one Contact has both couple names and the other has just the primary name.
  # e.g. "Doe, John and Jane" and "Doe, John" should be considered duplicates.
  def find_duplicates_by_primary_name
    find_duplicate_hashes_by_value(contact_names_hashes, :primary_name).each do |duplicate_hashes|
      return unless (duplicate_hashes.first[:rebuilt_name] == duplicate_hashes.first[:primary_name]) ||
                    (duplicate_hashes.second[:rebuilt_name] == duplicate_hashes.second[:primary_name])
      add_duplicate(duplicate_hashes.first[:contact_id], duplicate_hashes.second[:contact_id], 'Similar names')
    end
  end

  # Find duplicates where one Contact has both couple names and the other has just the spouse name.
  # e.g. "Doe, John and Jane" and "Doe, Jane" should be considered duplicates.
  def find_duplicates_by_spouse_or_primary_name
    find_duplicate_hashes_by_value(contact_names_hashes, :spouse_or_primary_name).each do |duplicate_hashes|
      return unless (duplicate_hashes.first[:rebuilt_name] == duplicate_hashes.first[:spouse_or_primary_name]) ||
                    (duplicate_hashes.second[:rebuilt_name] == duplicate_hashes.second[:spouse_or_primary_name])
      add_duplicate(duplicate_hashes.first[:contact_id], duplicate_hashes.second[:contact_id], 'Similar names')
    end
  end

  def build_hashes_for_comparing_donor_numbers
    ContactDonorAccount.joins(:donor_account).where(contact: contacts_scope).pluck(:contact_id, 'donor_accounts.account_number').collect do |contact_id_and_donor_number|
      { contact_id: contact_id_and_donor_number[0], donor_number: contact_id_and_donor_number[1] }
    end
  end

  def find_duplicates_by_donor_number
    contact_donor_numbers_hashes = build_hashes_for_comparing_donor_numbers

    find_duplicate_hashes_by_value(contact_donor_numbers_hashes, :donor_number).each do |duplicate_hashes|
      add_duplicate(duplicate_hashes.first[:contact_id], duplicate_hashes.second[:contact_id], 'Same donor account number')
    end
  end

  # Given an Array of Hashes, find duplicate Hashes by comparing a particular key/value in each Hash.
  # This method is designed for performance. Sorting the Array once and then looping once is much faster than if we used a nested loop.
  def find_duplicate_hashes_by_value(array_of_hashes, key_to_compare)
    # Sort the hashes by the value under key_to_compare so that we can search for duplicates faster.
    sorted_array_of_hashes = array_of_hashes.sort { |a, b| a[key_to_compare] <=> b[key_to_compare] }

    sorted_array_of_hashes.each_with_index.collect do |target_hash, index|
      # Find the next hash that has a different contact_id.
      next_index = index + 1
      next_hash = loop do
        next_hash = sorted_array_of_hashes[next_index]
        next_index += 1
        break next_hash unless next_hash && next_hash[:contact_id] == target_hash[:contact_id]
      end

      # Compare the hashes by their values under the key_to_compare.
      next unless next_hash && values_present_and_equal?(target_hash[key_to_compare], next_hash[key_to_compare])

      [next_hash, target_hash]
    end.compact
  end

  def add_duplicate(contact_id_one, contact_id_two, reason)
    return if duplicate_ids.include?(contact_id_two) || duplicate_ids.include?(contact_id_one)
    duplicate_ids << contact_id_one
    duplicate_ids << contact_id_two
    duplicate_record_pairs << build_duplicate_record_pair(contact_id_one, contact_id_two, reason)
  end

  def build_duplicate_record_pair(contact_id_one, contact_id_two, reason)
    DuplicateRecordPair.new(account_list: account_list, reason: reason,
                            record_one_id: contact_id_one, record_one_type: 'Contact',
                            record_two_id: contact_id_two, record_two_type: 'Contact')
  end

  def values_present_and_equal?(value_one, value_two)
    value_one.present? && value_two.present? && value_one == value_two
  end
end
