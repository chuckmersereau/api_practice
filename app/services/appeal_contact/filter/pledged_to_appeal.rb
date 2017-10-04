class AppealContact::Filter::PledgedToAppeal < AppealContact::Filter::Base
  def execute_query(appeal_contacts, filters)
    appeal_contacts_with_pledges = appeal_contacts.joins(contact: :pledges).where(pledges: { appeal_id: filters[:appeal_id] })

    if cast_bool_value(filters[:pledged_to_appeal])
      appeal_contacts.where(id: appeal_contacts_with_pledges)
    else
      appeal_contacts.where.not(id: appeal_contacts_with_pledges)
    end
  end

  private

  def valid_filters?(filters)
    return false unless filters[:appeal_id]
    filter_value = cast_bool_value(filters[name])
    [true, false].include? filter_value
  end
end
