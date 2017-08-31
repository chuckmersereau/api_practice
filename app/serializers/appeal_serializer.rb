class AppealSerializer < ApplicationSerializer
  attributes :amount,
             :currencies,
             :description,
             :end_date,
             :name,
             :pledges_amount_not_received_not_processed,
             :pledges_amount_processed,
             :pledges_amount_received_not_processed,
             :pledges_amount_total,
             :total_currency

  belongs_to :account_list
  has_many :contacts
  has_many :donations

  def currencies
    object.donations.currencies
  end

  def total_currency
    object.account_list.salary_currency_or_default
  end
end
