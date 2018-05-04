class AddPledgeCurrencyToPartnerStatusLogs < ActiveRecord::Migration
  def change
    add_column :partner_status_logs, :pledge_currency, :string
  end
end
