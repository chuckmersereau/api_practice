class AddUuidToContactReferrals < ActiveRecord::Migration
  def change
    add_column :contact_referrals, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :contact_referrals, :uuid, unique: true
  end
end
