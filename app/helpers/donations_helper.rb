module DonationsHelper
  def totals_by_currency(donations)
    donations.group_by { |d| d.currency == '' ? current_account_list.default_currency : d.currency }
      .map do |currency, amount|
      {
        currency: currency,
        count: amount.sum { 1 },
        sum: amount.sum { |j| j.amount.to_f }
      }
    end
  end
end
