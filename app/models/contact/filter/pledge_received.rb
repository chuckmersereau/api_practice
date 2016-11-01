class Contact::Filter::PledgeReceived < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      contacts.where(pledge_received: filters[:pledge_received])
    end

    def title
      _('Commitment Received')
    end

    def parent
      _('Commitment Details')
    end

    def type
      'radio'
    end

    def custom_options(_account_list)
      [{ name: _('Received'), id: 'true' }, { name: _('Not Received'), id: 'false' }]
    end
  end
end