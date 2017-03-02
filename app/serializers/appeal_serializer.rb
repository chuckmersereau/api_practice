class AppealSerializer < ApplicationSerializer
  attributes :amount,
             :currencies,
             :description,
             :donations,
             :end_date,
             :name,
             :total_currency

  belongs_to :account_list
  has_many :contacts

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

  def account_list_id
    object.account_list.uuid
  end
end
