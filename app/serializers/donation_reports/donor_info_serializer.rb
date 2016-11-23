class DonationReports::DonorInfoSerializer < ApplicationSerializer
  attributes :amount,
             :contact_id,
             :converted_amount,
             :currency,
             :donation_date,
             :pledge_amount,
             :pledge_frequency,
             :status

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
