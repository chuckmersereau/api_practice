class ExcludedAppealContactSerializer < ApplicationSerializer
  attributes :donations,
             :reasons

  belongs_to :appeal
  belongs_to :contact

  def donations
    object.contact.donations.where(donation_date: start_date..end_date).collect do |d|
      d.attributes.with_indifferent_access.slice(:currency, :amount, :donation_date)
    end
  end

  def start_date
    (end_date - 6.months).beginning_of_month
  end

  def end_date
    Time.zone.today
  end

  def reasons
    object.reasons.map do |r|
      case r
      when 'marked_do_not_ask'
        _('Are marked as do not ask for appeals')
      when 'joined_recently'
        _('Joined my team in the last 3 months')
      when 'special_gift'
        _('Gave a special gift in the last 3 months')
      when 'stopped_giving'
        _('Stopped giving for the last 2 months')
      when 'increased_recently'
        _('Increased their giving in the last 3 months')
      end
    end
  end
end
