class Reports::SalaryCurrencyDonations < Reports::DonorCurrencyDonations
  def donation_currency(donation)
    donation.converted_currency
  end

  def donation_amount(donation)
    donation.converted_amount
  end
end
