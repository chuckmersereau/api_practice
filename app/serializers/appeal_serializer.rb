class AppealSerializer < ActiveModel::Serializer
  embed :ids, include: true
  # has_many :contacts
  ATTRIBUTES = [:id, :name, :amount, :description, :end_date, :created_at, :currencies,
                :total_currency, :donations].freeze
  attributes(*ATTRIBUTES)

  attribute :contact_ids, key: :contacts

  def contact_ids
    object.contacts.order(:name).pluck(:id)
  end

  def currencies
    object.donations.currencies
  end

  def total_currency
    object.account_list.salary_currency_or_default
  end

  def donations
    object.donations.map do |donation|
      hash = donation.attributes.slice('amount', 'appeal_amount', 'donation_date', 'donor_account_id',
                                       'currency')
      converted_amount = CurrencyRate.convert_on_date(amount: donation.appeal_amount || donation.amount,
                                                      from: donation.currency,
                                                      to: total_currency,
                                                      date: donation.donation_date)
      hash.merge(converted_amount: converted_amount)
    end
  end
end
