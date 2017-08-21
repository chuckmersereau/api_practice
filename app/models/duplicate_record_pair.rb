class DuplicateRecordPair < ApplicationRecord
  PERMITTED_ATTRIBUTES = [
    :account_list_id,
    :created_at,
    :ignore,
    :overwrite,
    :reason,
    :record_one_id,
    :record_two_id,
    :updated_at,
    :updated_in_db_at,
    :uuid
  ].freeze

  belongs_to :record_one, polymorphic: true
  belongs_to :record_two, polymorphic: true
  belongs_to :account_list

  before_save :sort_record_ids

  validates :account_list_id, :record_one_id, :record_one_type, :record_two_id, :record_two_type, :reason, presence: true
  validates :record_one_type, :record_two_type, inclusion: { in: %w(Contact) }
  validate :records_have_the_same_type_validation
  validate :records_belong_to_the_same_account_list_validation
  validate :pair_is_unique_validation
  validate :a_record_cannot_be_in_multiple_pairs_validation

  scope :type, -> (type) { where(record_one_type: type, record_two_type: type) }

  def type
    record_one_type == record_two_type ? record_one_type : nil
  end

  def records
    [record_one, record_two]
  end

  def ids
    [record_one_id, record_two_id]
  end

  private

  # It doesn't matter whether a record is in record_one or record_two.
  # We sort the record ids so that the db index can enforce uniqueness across both ids.
  def sort_record_ids
    self.record_one_id, self.record_two_id = ids.sort
  end

  def records_have_the_same_type_validation
    return if record_one_type == record_two_type
    errors.add(:base, 'Records must have the same type!')
  end

  def records_belong_to_the_same_account_list_validation
    return if record_one&.account_list_id == account_list&.id && record_two&.account_list_id == account_list&.id
    errors.add(:base, 'Records must belong to the same AccountList!')
  end

  # We don't let a record into multiple pairs because if one of those pairs is merged then the original record may be deleted,
  # and in that case dealing with the next pair is challenging because the record no longer exists.
  def a_record_cannot_be_in_multiple_pairs_validation
    return unless DuplicateRecordPair.type(type).where.not(id: id).where(ignore: false).where('record_one_id IN (:ids) OR record_two_id IN (:ids)', ids: ids).exists?
    errors.add(:base, 'A record cannot be in multiple pairs (unless the pair is ignored first)!')
  end

  def pair_is_unique_validation
    return unless DuplicateRecordPair.type(type).where.not(id: id).where(record_one_id: ids, record_two_id: ids).exists?
    errors.add(:base, 'Each duplicate pair should be unique!')
  end
end
