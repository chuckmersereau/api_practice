class Contact::Filter::DonationDate < Contact::Filter::Base
  def execute_query(contacts, filters)
    # Contact::Filter::Donation handles date range if looking for no donations during period
    return contacts if filters[:donation] == 'none'

    params = daterange_params(filters[:donation_date])
    contacts = contacts.joins(donor_accounts: [:donations]) if params.present?
    if params[:start]
      contacts = contacts.where('donations.donation_date >= :date_range_start AND '\
                                'donations.designation_account_id IN (:designation_account_ids)',
                                date_range_start: params[:start], designation_account_ids: designation_account_ids)
    end
    if params[:end]
      contacts = contacts.where('donations.donation_date <= :date_range_end AND '\
                               'donations.designation_account_id IN (:designation_account_ids)',
                                date_range_end: params[:end], designation_account_ids: designation_account_ids)
    end
    contacts
  end

  def title
    _('Gift Date')
  end

  def parent
    _('Gift Details')
  end

  def type
    'daterange'
  end

  def custom_options
    [
      {
        name: _('Last 30 Days'),
        start: 30.days.ago.beginning_of_day,
        end: Time.current
      },
      {
        name: _('This Month'),
        start: Time.current.beginning_of_month + 1.hour,
        end: Time.current.end_of_month
      },
      {
        name: _('Last Month'),
        start: 1.month.ago.beginning_of_month + 1.hour,
        end: 1.month.ago.end_of_month
      },
      {
        name: _('Last Two Months'),
        start: 2.months.ago.beginning_of_month + 1.hour,
        end: Time.current.beginning_of_month
      },
      {
        name: _('Last Three Months'),
        start: 3.months.ago.beginning_of_month + 1.hour,
        end: Time.current.beginning_of_month
      },
      {
        name: _('This Year'),
        start: Time.current.beginning_of_year + 1.hour,
        end: Time.current.end_of_year
      },
      {
        name: _('Last Year'),
        start: 1.year.ago.beginning_of_year + 1.hour,
        end: 1.year.ago.end_of_year
      }
    ]
  end

  def valid_filters?(filters)
    super && daterange_params(filters[:donation_date]).present?
  end
end
