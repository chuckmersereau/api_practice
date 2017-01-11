class DonationReports::DonorInfoSerializer < ServiceSerializer
  attributes :contact_id,
             :contact_name,
             :late_by_30_days,
             :late_by_60_days,
             :pledge_amount,
             :pledge_currency,
             :pledge_frequency,
             :status

  delegate :contact_id,
           :contact_name,
           :late_by_30_days,
           :late_by_60_days,
           :pledge_currency,
           to: :object

  def status
    _(object.status)
  end

  def pledge_frequency
    _(Contact.pledge_frequencies[object.pledge_frequency])
  end

  def pledge_amount
    object.pledge_amount.to_f
  end
end
