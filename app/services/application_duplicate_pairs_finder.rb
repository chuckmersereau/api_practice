# This abstract class provides base behaviour for finding duplicate records within the given AccountList.
#
# The general process to find duplicates would go like this:
#
#   1. Load record data from the database into hashes.
#   2. Find duplicates by comparing values in the hashes.
#   3. Create DuplicateRecordPair records in the database.

class ApplicationDuplicatePairsFinder
  attr_reader :account_list, :duplicate_ids, :duplicate_record_pairs

  def initialize(account_list)
    @account_list = account_list
    @duplicate_ids = Set.new
    @duplicate_record_pairs = []
    raise "record_type #{record_type} is not valid!" unless DuplicateRecordPair::TYPES.include?(record_type)
  end

  def find_and_save
    delete_pairs_with_missing_records
    find_duplicates
    duplicate_record_pairs.select(&:save)
  end

  private

  def delete_pairs_with_missing_records
    association = record_type.pluralize.downcase
    all_records_scope = account_list.send(association)
    [:record_one_id, :record_two_id].each do |id_attribute|
      account_list.duplicate_record_pairs.type(record_type).where.not(id_attribute => all_records_scope).delete_all
    end
  end

  def find_duplicates
    raise 'This method should be overloaded by the child class'
  end

  def record_type
    @record_type ||= self.class.to_s.split(':').first
  end

  # Given an Array of Hashes, find duplicate Hashes by comparing a particular key/value in each Hash.
  # This method is designed for performance. Sorting the Array once and then looping once is much faster than if we used a nested loop.
  # It assumes that each hash has an "id" key with value. Hashes with the same id will never be considered duplicates.
  def find_duplicate_hashes_by_value(array_of_hashes, key_to_compare, comparison_method_name = :values_present_and_equal?)
    # Sort the hashes by the value under key_to_compare, so that we can search for duplicates faster.
    sorted_hashes = array_of_hashes.sort { |a, b| a[key_to_compare] <=> b[key_to_compare] }

    sorted_hashes.each_with_index.collect do |target_hash, index|
      next_hash = find_next_hash_to_compare(sorted_hashes: sorted_hashes, target_hash: target_hash, target_hash_index: index)

      # Compare the hashes by their values under the key_to_compare.
      next unless next_hash && send(comparison_method_name, target_hash[key_to_compare], next_hash[key_to_compare])

      [next_hash, target_hash]
    end.compact
  end

  # Find the next hash that has a different id, starting from the target_hash_index.
  def find_next_hash_to_compare(sorted_hashes:, target_hash:, target_hash_index:)
    index = target_hash_index
    loop do
      index += 1
      next_hash = sorted_hashes[index]
      break next_hash unless next_hash && next_hash[:id] == target_hash[:id]
    end
  end

  def values_present_and_equal?(value_one, value_two)
    value_one.present? && value_two.present? && value_one == value_two
  end

  def values_present_and_intersecting?(value_one, value_two)
    value_one.present? && value_two.present? && (value_one & value_two).present?
  end

  def add_duplicate_pair_from_hashes(duplicates, reason)
    record_one_id = duplicates.first[:id]
    record_two_id = duplicates.second[:id]
    return if duplicate_ids.include?(record_one_id) || duplicate_ids.include?(record_two_id)
    duplicate_ids << record_one_id
    duplicate_ids << record_two_id
    duplicate_record_pairs << build_duplicate_record_pair(record_one_id, record_two_id, reason)
  end

  def build_duplicate_record_pair(record_one_id, record_two_id, reason)
    DuplicateRecordPair.new(account_list_id: account_list.id, reason: reason,
                            record_one_id: record_one_id, record_one_type: record_type,
                            record_two_id: record_two_id, record_two_type: record_type)
  end
end
