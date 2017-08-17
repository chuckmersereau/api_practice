class AppealSerializer < ApplicationSerializer
  attributes :amount,
             :currencies,
             :description,
             :end_date,
             :name,
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
