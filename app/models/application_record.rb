require 'securerandom'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  before_save :generate_uuid, on: :create

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
