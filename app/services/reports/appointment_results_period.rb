class Reports::AppointmentResultsPeriod < ActiveModelSerializers::Model
  attr_accessor :account_list, :start_date, :end_date

  def individual_appointments
    appointments_during_dates.count
  end

  def group_appointments
    0
  end

  def new_monthly_partners
    @new_monthly_partners ||= cached_changed_contacts_with_pledges.count do |monthly_increase|
      monthly_increase.beginning_monthly.zero? && monthly_increase.end_monthly.positive?
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
    pledge_increase_contacts.sum(&:increase_amount)
  end

  def pledge_increase
    new_pledges.sum(:amount)
  end

  def new_pledges
    Pledge.where(appeal: account_list.primary_appeal, created_at: start_date..end_date)
  end

  def pledge_increase_contacts
    @pledge_increase_contacts ||= cached_changed_contacts_with_pledges.select do |monthly_increase|
      monthly_increase.increase_amount.positive?
    end
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

    contacts_with_changes.map do |contact|
      old_status = logs.find { |log| log.contact_id == contact.id }
      end_status = logs.find { |log| log.contact_id == contact.id && log.recorded_on > end_date.to_date }
      ::Reports::PledgeIncreaseContact.new(contact: contact, beginning: old_status, end_status: end_status)
    end
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
