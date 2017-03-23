class PhoneNumberSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper

  attributes :country_code,
             :historic,
             :number,
             :location,
             :primary,
             :source,
             :valid_values

  delegate :number, to: :phone_number_exhibit

  def phone_number_exhibit
    exhibit(object)
  end
end
