class UpdatePersonLinkedinAccountsPublicUrlLength < ActiveRecord::Migration
  def change
    change_column :person_linkedin_accounts, :public_url, :text
  end
end
