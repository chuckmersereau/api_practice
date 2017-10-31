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

  def date_range?(param)
    # we are expecting the param to be range of dates, if it is a range and in the correct direction,
    # `min` will return the first value, otherwise `min` will be nil
    param.is_a?(Range) && param.first.is_a?(Date) && param.min
  end
end
