class Contact::Filter::PledgeLateBy < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      return contacts unless filters[:pledge_late_by]
      min_days, max_days = filters[:pledge_late_by].split('_').map(&:to_i).map(&:days)
      contacts.late_by(min_days, max_days)
    end

    def title
      _('Late By')
    end

    def parent
      _('Commitment Details')
    end

    def type
      'radio'
    end

    def custom_options(_account_list)
      [{ name: _('Less than 30 days late'), id: '0_30' },
       { name: _('More than 30 days late'), id: '30_60' },
       { name: _('More than 60 days late'), id: '60_90' },
       { name: _('More than 90 days late'), id: '90' }]
    end
  end
end
