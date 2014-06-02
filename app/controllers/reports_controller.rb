class ReportsController < ApplicationController
  def contributions
    @page_title = _('Contribution Report')

    if params[:start_date]
      @start_date = Date.parse(params[:start_date])
      @end_date = @start_date.end_of_month + 11.months
    else
      @end_date = Date.today.end_of_month
      @start_date = 11.month.ago(@end_date).beginning_of_month
    end
    @raw_donations = current_account_list
      .donations
      .where("donation_date BETWEEN ? AND ?", @start_date, @end_date)
      .select('"donations"."donor_account_id",' +
              'date_trunc(\'month\', "donations"."donation_date"),' +
              'SUM("donations"."tendered_amount") as tendered_amount,' +
              '"donations"."tendered_currency",' +
              '"donor_accounts"."name",' +
              '"contact_donor_accounts"."contact_id" as contact_id'
      )
      .where("contacts.account_list_id" => current_account_list.id)
      .joins(donor_account: [:contacts])
      .group('donations.donor_account_id, ' +
             'date_trunc, ' +
             'tendered_currency, ' +
             'donor_accounts.name, ' +
             'contact_donor_accounts.id')
      .reorder('donor_accounts.name')
      .to_a
    @donations = {}
    @sum_row = {}
    @raw_donations.each do |donation|
      @donations[donation.donor_account_id] ||= { donor: donation.name,
                                                  id: donation.contact_id,
                                                  amounts: {},
                                                  total: 0 }

      @donations[donation.donor_account_id][:amounts][donation.date_trunc.strftime '%b %y'] = {
          value: donation.tendered_amount,
          currency: donation.tendered_currency
      }

      @donations[donation.donor_account_id][:total] += donation.tendered_amount

      @sum_row[donation.date_trunc.strftime '%b %y'] ||= 0

      @sum_row[donation.date_trunc.strftime '%b %y'] += donation.tendered_amount
    end
  end
end