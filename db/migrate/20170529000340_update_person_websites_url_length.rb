class UpdatePersonWebsitesUrlLength < ActiveRecord::Migration
  def change
    change_column :person_websites, :url, :text
  end
end
