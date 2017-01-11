class Reports::YearDonationsSerializer < ServiceSerializer
  delegate :account_list,
           :donation_infos,
           :donor_infos,
           to: :object

  belongs_to :account_list

  attributes :donor_infos,
             :donation_infos
end
