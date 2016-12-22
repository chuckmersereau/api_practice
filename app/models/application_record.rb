require 'securerandom'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  attr_accessor :updated_in_db_at

  before_save :generate_uuid, on: :create
  validate :presence_of_updated_in_db_at, on: :update_from_controller
  validate :value_of_updated_in_db_at, on: :update_from_controller

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def presence_of_updated_in_db_at
    return if updated_in_db_at
    errors.add(:updated_in_db_at,
               'has to be sent in the list of attributes in order to update resource')
  end

  def value_of_updated_in_db_at
    return if updated_at_was.to_s == updated_in_db_at.to_s
    errors.add(:updated_in_db_at, 'is not equal to the current value in the database')
  end
end
