module Concerns::BeforeCreateSetValidValuesBasedOnSource
  extend ActiveSupport::Concern

  included do
    before_create do
      self.valid_values = (source == 'MPDX')
      true
    end
  end
end
