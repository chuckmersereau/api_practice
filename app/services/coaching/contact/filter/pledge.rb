module Coaching::Contact
  class Filter::Pledge < Filter::Base
    def execute_query(contacts, filters)
      case filters[:pledge]
      when 'completed'
        contacts.financial_partners.where(pledge_received: true)
      when 'outstanding'
        contacts.financial_partners
                .where(pledge_received: false)
                .where('pledge_start_date < ?', today)
      when 'pending'
        contacts.financial_partners
                .where(pledge_received: false)
                .where('pledge_start_date >= ?', today)
      else # 'all'
        contacts.all
      end
    end

    def title
      _('Pledge Status')
    end

    def type
      'radio'
    end

    def default_options
      []
    end

    def custom_options
      [{ name: _('-- All --'), id: 'all' },
       { name: _('Outstanding'), id: 'outstanding' },
       { name: _('Completed'), id: 'completed' },
       { name: _('Pending'), id: 'pending' }]
    end

    private

    def today
      Time.zone.now.to_date
    end
  end
end
