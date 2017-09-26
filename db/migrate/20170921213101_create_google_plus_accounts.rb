class CreateGooglePlusAccounts < ActiveRecord::Migration
  def change
    create_table :google_plus_accounts do |t|
      t.string :account_id
      t.string :profile_picture_link
      t.uuid :uuid, default: 'uuid_generate_v4()'

      t.belongs_to :email_address, index: true

      t.timestamps null: false
    end
  end
end
