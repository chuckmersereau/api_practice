class DonationReports::DonorInfoSerializer < ActiveModel::Serializer
  attributes(*DonationReports::DonorInfo::ATTRIBUTES)

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
