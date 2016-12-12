class DonationReports::DonorInfoSerializer < ApplicationSerializer
  attributes :amount,
             :converted_amount,
             :currency,
             :donation_date,
             :pledge_amount,
             :pledge_frequency,
             :status

  belongs_to :contact

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
