module Concerns::AfterValidationSetSourceToMPDX
  extend ActiveSupport::Concern

  included do
    after_validation do
      self.source = Address::MANUAL_SOURCE if source_should_be_changed_to_mpdx?
      true
    end
  end

  private

  def source_should_be_changed_to_mpdx?
    persisted? &&
      errors.none? &&
      source == 'TntImport' &&
      !changes.keys.map(&:to_sym).include?(:source) &&
      changes.any? { |_attribute, values| values.second.present? }
  end
end
