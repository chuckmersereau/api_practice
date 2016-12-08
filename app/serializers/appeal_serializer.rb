class AppealSerializer < ApplicationSerializer
  attributes :account_list_id,
             :amount,
             :currencies,
             :description,
             :donations,
             :end_date,
             :name,
             :total_currency

  has_many :contacts
  belongs_to :account_list

  def currencies
    object.donations.currencies
  end

  def total_currency
    object.account_list.salary_currency_or_default
  end

  def donations
    object.donations.map do |donation|
      donation_attributes(donation).merge(converted_amount: converted_amount(donation))
    end
  end

  def donation_attributes(donation)
    donation.attributes.slice('amount', 'appeal_amount', 'donation_date', 'donor_account_id', 'currency')
  end

  def converted_amount(donation)
    CurrencyRate.convert_on_date(amount: donation.appeal_amount || donation.amount,
                                 from: donation.currency,
                                 to: total_currency,
                                 date: donation.donation_date)
  end
end
