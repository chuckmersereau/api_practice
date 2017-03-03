class Reports::DonorCurrencyDonationsSerializer < ServiceSerializer
  delegate :account_list,
           :donor_infos,
           :months,
           :currency_groups,
           to: :object
  delegate :salary_currency,
           to: :account_list

  belongs_to :account_list

  attributes :donor_infos,
             :months,
             :currency_groups,
             :salary_currency
end
