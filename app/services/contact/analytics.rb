class Contact::Analytics
  alias read_attribute_for_serialization send

  attr_reader :contacts

  def initialize(contacts)
    @contacts = contacts
  end

  def id
  end

  def first_gift_not_received_count
    contacts.financial_partners
            .where(pledge_received: false)
            .count
  end

  def partners_30_days_late_count
    contacts.late_by(31.days, 60.days).count
  end

  def partners_60_days_late_count
    contacts.late_by(61.days).count
  end

  def birthdays_this_week
    fetch_people_with_birthdays_this_week_who_are_alive_from_active_contacts
  end

  def anniversaries_this_week
    fetch_active_contacts_who_have_people_with_anniversaries_this_week
  end

  private

  def beginning_of_week
    @beginning_of_week ||= Time.current.beginning_of_week
  end

  def end_of_week
    @end_of_week ||= Time.current.end_of_week
  end

  def fetch_active_contacts_who_have_people_with_anniversaries_this_week
    people_ids = fetch_people_with_anniversaries_this_week_who_are_alive
                 .select(:id)

    contacts
      .active
      .joins(:contact_people)
      .where(contact_people: { person_id: people_ids })
  end

  def fetch_people_with_birthdays_this_week_who_are_alive_from_active_contacts
    contact_ids = contacts.active.select(:id)

    Person.joins(:contact_people)
          .where(contact_people: { contact_id: contact_ids })
          .with_birthday_between(beginning_of_week, end_of_week)
          .alive
          .by_birthday
  end

  def fetch_people_with_anniversaries_this_week_who_are_alive
    Person.with_anniversary_between(beginning_of_week, end_of_week)
          .by_anniversary
          .alive
  end
end
