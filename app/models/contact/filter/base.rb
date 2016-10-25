class Contact::Filter::Base < ApplicationFilter
  class << self
    protected

    def contact_ids_with_phone(contacts, location)
      contacts
        .where.not(phone_numbers: { number: nil })
        .where(phone_numbers: { historic: false, location: location })
        .includes(people: :phone_numbers)
        .pluck(:id)
    end

    def contact_instance
      @@contact_instance ||= Contact.new
    end
  end
end
