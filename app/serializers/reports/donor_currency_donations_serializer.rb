class Reports::DonorCurrencyDonationsSerializer < ServiceSerializer
  delegate :account_list,
           :donor_infos,
           :months,
           :currency_groups,
           to: :object

  belongs_to :account_list

  attributes :donor_infos,
             :months,
             :currency_groups
end
