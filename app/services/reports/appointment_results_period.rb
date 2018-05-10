class Reports::AppointmentResultsPeriod < ActiveModelSerializers::Model
  attr_accessor :account_list, :start_date, :end_date

  def individual_appointments
    appointments_during_dates.count
  end

  def group_appointments
    0
  end

  def new_monthly_partners
    cached_changed_contacts_with_pledges.count do |_contact, pledges|
      pledges[:beginning].zero? && pledges[:end].positive?
    end
  end

  def new_special_pledges
    return 0 unless account_list.primary_appeal_id.present?
    account_list.contacts
                .joins(:pledges)
                .where(pledges: { appeal: account_list.primary_appeal, created_at: start_date..end_date })
                .count
  end

  def monthly_increase
    cached_changed_contacts_with_pledges.sum do |contact, pledges|
      delta = pledges[:end] - pledges[:beginning]
      next 0 unless delta.positive?
      CurrencyRate.convert_with_latest(amount: delta,
                                       from: contact.pledge_currency,
                                       to: account_list.salary_currency_or_default)
    end.to_i
  end

  def pledge_increase
    Pledge.where(appeal: account_list.primary_appeal, created_at: start_date..end_date).sum(:amount)
  end

  private

  def cached_changed_contacts_with_pledges
    @changed_contacts_with_pledges ||= changed_contacts_with_pledges
  end

  def changed_contacts_with_pledges
    ids = (changed_contacts + new_financial_partners.pluck(:id)).uniq
    contacts_with_changes = account_list.contacts.where(id: ids).to_a

    # it might be just as fast to load all of the logs at once
    logs = PartnerStatusLog.where(contact_id: ids).where('recorded_on >= ?', start_date).order(recorded_on: :asc)

    contacts_with_changes.each_with_object({}) do |contact, hash|
      old_status = logs.find { |log| log.contact_id == contact.id }
      old_pledge = pledge_from_status(old_status)

      end_status = logs.find { |log| log.contact_id == contact.id && log.recorded_on > end_date.to_date }
      # use current contact values if there have been no changes since the end of the window
      end_status ||= contact
      end_pledge = pledge_from_status(end_status)

      hash[contact] = { beginning: old_pledge, end: end_pledge }
    end
  end

  def pledge_from_status(status)
    return 0 unless status&.status == 'Partner - Financial'

    status.pledge_amount.to_i / (status.pledge_frequency || 1)
  end

  def changed_contacts
    # we want to know which people ever changed during the period
    PartnerStatusLog.joins(:contact)
                    .where(contacts: { account_list_id: account_list.id }, recorded_on: start_date..end_date)
                    .pluck(:contact_id)
  end

  def new_financial_partners
    account_list.contacts.where(created_at: start_date..end_date, status: 'Partner - Financial')
  end

  def appointments_during_dates(type = 'Appointment')
    account_list.tasks.completed.where(activity_type: type, start_at: start_date..end_date, result: %w(Completed Done))
  end
end
