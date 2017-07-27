class Contact::Filter::Base < ApplicationFilter
  protected

  def contact_ids_with_phone(contacts, location)
    contacts
      .where.not(phone_numbers: { number: nil })
      .where(phone_numbers: { historic: false, location: location })
      .joins(people: :phone_numbers)
      .pluck(:id)
  end

  def contact_instance
    @@contact_instance ||= Contact.new
  end

  private

  def designation_account_ids
    account_lists.map(&:designation_account_ids).flatten
  end
end
