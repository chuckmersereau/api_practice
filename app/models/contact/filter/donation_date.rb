class Contact::Filter::DonationDate < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
      params = daterange_params(filters[:donation_date])
      contacts = contacts.includes(donor_accounts: [:donations]).references(donor_accounts: [:donations]) if params.present?
      contacts = contacts.where('donations.donation_date >= ?', params[:start]) if params[:start]
      contacts = contacts.where('donations.donation_date <= ?', params[:end]) if params[:end]
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

    def custom_options(_account_lists)
      [
        { name: _('Last 30 Days'), start: 30.days.ago.beginning_of_day, end: Time.current },
        { name: _('This Month'), start: Time.current.beginning_of_month + 1.hour, end: Time.current.end_of_month },
        { name: _('Last Month'), start: 1.month.ago.beginning_of_month + 1.hour, end: 1.month.ago.end_of_month },
        { name: _('Last Two Months'), start: 2.months.ago.beginning_of_month + 1.hour, end: Time.current.beginning_of_month },
        { name: _('Last Three Months'), start: 3.months.ago.beginning_of_month + 1.hour, end: Time.current.beginning_of_month },
        { name: _('This Year'), start: Time.current.beginning_of_year + 1.hour, end: Time.current.end_of_year },
        { name: _('Last Year'), start: 1.year.ago.beginning_of_year + 1.hour, end: 1.year.ago.end_of_year }
      ]
    end

    def valid_filters?(filters)
      super && daterange_params(filters[:donation_date]).present?
    end
  end
end
