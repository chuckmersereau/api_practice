module Coaching::Pledge
  class Filter::Status < Filter::Base
    def execute_query(pledges, filters)
      case filters[:status]
      when 'completed'
        pledges.where(status: :processed)
      when 'outstanding'
        pledges.where(status: :not_received).where('expected_date < ?', today)
      when 'pending'
        pledges.where(status: :not_received).where('expected_date >= ?', today)
      when 'received_not_processed'
        pledges.where(status: :received_not_processed)
      else # 'all'
        pledges.all
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
       { name: _('Pending'), id: 'pending' },
       { name: _('Received, but not Processed'), id: 'received_not_processed' }]
    end

    private

    def today
      Time.zone.now.to_date
    end
  end
end
