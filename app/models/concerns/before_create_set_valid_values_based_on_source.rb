module Concerns::BeforeCreateSetValidValuesBasedOnSource
  extend ActiveSupport::Concern

  included do
    before_create do
      self.valid_values = (source == Address::MANUAL_SOURCE)
      true
    end
  end
end
