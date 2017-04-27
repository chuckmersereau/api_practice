require 'securerandom'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  CONFLICT_ERROR_MESSAGE = 'is not equal to the current value in the database'.freeze

  attr_reader :updated_in_db_at
  attr_accessor :overwrite

  before_save :generate_uuid, on: :create

  validate :presence_of_updated_in_db_at,
           :value_of_updated_in_db_at,
           on: :update_from_controller,
           unless: :should_overwrite?

  def updated_in_db_at=(value)
    @updated_in_db_at = value&.is_a?(Time) ? value : Time.parse(value.to_s)
  end

  # for better error messages when finding a resource by UUID
  def self.find_by_uuid_or_raise!(uuid)
    if uuid && !uuid.empty?
      find_by(uuid: uuid) || record_from_uuid_not_found_error(uuid)
    else
      record_from_uuid_not_found_error(uuid)
    end
  end

  def self.preload_valid_associations(*args)
    associations = args.select { |association| reflections.keys.include?(association) }
    return preload(*associations) unless associations.empty?
    self
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def presence_of_updated_in_db_at
    return if updated_in_db_at
    errors.add(:updated_in_db_at, 'has to be sent in the list of attributes in order to update resource')
  end

  def value_of_updated_in_db_at
    return if updated_at_was.to_i == updated_in_db_at.to_i
    errors.add(:updated_in_db_at, full_conflict_error_message)
  end

  def full_conflict_error_message
    "#{CONFLICT_ERROR_MESSAGE} (#{updated_at_was&.to_time&.utc&.iso8601})"
  end

  def should_overwrite?
    overwrite.to_s.to_sym == :true
  end

  def self.record_from_uuid_not_found_error(uuid)
    message = "Couldn't find #{name} with 'uuid'=#{uuid}"

    raise ActiveRecord::RecordNotFound, message
  end

  private_class_method :record_from_uuid_not_found_error
end
