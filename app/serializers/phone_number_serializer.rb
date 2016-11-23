class PhoneNumberSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper

  attributes :country_code,
             :historic,
             :number,
             :location,
             :primary

  delegate :number, to: :phone_number_exhibit

  def phone_number_exhibit
    exhibit(object)
  end
end
