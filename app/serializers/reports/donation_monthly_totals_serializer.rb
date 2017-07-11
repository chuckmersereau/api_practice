class Reports::DonationMonthlyTotalsSerializer < ServiceSerializer
  delegate :donation_totals_by_month,
           to: :object

  attributes :donation_totals_by_month
end
