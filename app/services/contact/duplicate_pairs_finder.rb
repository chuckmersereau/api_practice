# This class finds and saves DuplicateRecordPair records by looking through all Contacts in the given AccountList.
# Duplicates are found primarily by comparing the Contact names and DonorAccount numbers.

class Contact::DuplicatePairsFinder < ApplicationDuplicatePairsFinder
  private

  def find_duplicates
    find_duplicates_by_name
    find_duplicates_by_donor_number
  end

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

      spouse_name = Contact::NameBuilder.new(parsed_name.slice(:spouse_first_name, :spouse_last_name)).name.presence
      {
        id: contact_id,
        original_name: original_name.squish,
        rebuilt_name: Contact::NameBuilder.new(original_name).name,
        primary_name: primary_name,
        spouse_or_primary_name: spouse_name || primary_name
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
      add_duplicate_pair_from_hashes(duplicate_hashes, 'Similar names')
    end
  end

  # We rebuild the name so that we can compare a consistent format of the name.
  # e.g. "John H. Doe" and "Doe, John" should be considered duplicates.
  def find_duplicates_by_rebuilt_name
    find_duplicate_hashes_by_value(contact_names_hashes, :rebuilt_name).each do |duplicate_hashes|
      add_duplicate_pair_from_hashes(duplicate_hashes, 'Similar names')
    end
  end

  # Find duplicates where one Contact has both couple names and the other has just the primary name.
  # e.g. "Doe, John and Jane" and "Doe, John" should be considered duplicates.
  def find_duplicates_by_primary_name
    find_duplicate_hashes_by_value(contact_names_hashes, :primary_name).each do |duplicate_hashes|
      break unless (duplicate_hashes.first[:rebuilt_name] == duplicate_hashes.first[:primary_name]) ||
                   (duplicate_hashes.second[:rebuilt_name] == duplicate_hashes.second[:primary_name])
      add_duplicate_pair_from_hashes(duplicate_hashes, 'Similar names')
    end
  end

  # Find duplicates where one Contact has both couple names and the other has just the spouse name.
  # e.g. "Doe, John and Jane" and "Doe, Jane" should be considered duplicates.
  def find_duplicates_by_spouse_or_primary_name
    find_duplicate_hashes_by_value(contact_names_hashes, :spouse_or_primary_name).each do |duplicate_hashes|
      break unless (duplicate_hashes.first[:rebuilt_name] == duplicate_hashes.first[:spouse_or_primary_name]) ||
                   (duplicate_hashes.second[:rebuilt_name] == duplicate_hashes.second[:spouse_or_primary_name])
      add_duplicate_pair_from_hashes(duplicate_hashes, 'Similar names')
    end
  end

  def build_hashes_for_comparing_donor_numbers
    contact_account_numbers = ContactDonorAccount.joins(:donor_account)
                                                 .where(contact: contacts_scope)
                                                 .pluck(:contact_id, 'donor_accounts.account_number')
    contact_account_numbers.collect do |contact_id_and_donor_number|
      { id: contact_id_and_donor_number[0], donor_number: contact_id_and_donor_number[1] }
    end
  end

  def find_duplicates_by_donor_number
    contact_donor_numbers_hashes = build_hashes_for_comparing_donor_numbers

    find_duplicate_hashes_by_value(contact_donor_numbers_hashes, :donor_number).each do |duplicate_hashes|
      add_duplicate_pair_from_hashes(duplicate_hashes, 'Same donor account number')
    end
  end
end
