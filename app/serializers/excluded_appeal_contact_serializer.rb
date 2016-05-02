class ExcludedAppealContactSerializer < ActiveModel::Serializer
  attributes :id, :appeal_id, :contact, :donations, :reasons

  def donations
    end_date = Time.zone.today
    start_date = (end_date - 6.months).beginning_of_month
    object.contact.donations.where(donation_date: start_date..end_date).collect do |d|
      d.attributes.with_indifferent_access.slice(:currency, :amount, :donation_date)
    end
  end

  def contact
    object.contact.attributes
          .with_indifferent_access
          .slice(:id, :name, :pledge_amount, :status, :pledge_frequency)
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
