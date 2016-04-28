class ExcludedAppealContactSerializer < ActiveModel::Serializer
  attributes :id, :appeal_id, :contact, :donations

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
end
