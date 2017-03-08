class CreateContactReferrals < ActiveRecord::Migration
  def change
    create_table :contact_referrals do |t|
      t.belongs_to :referred_by
      t.belongs_to :referred_to

      t.timestamps null: false
    end
    add_index :contact_referrals, [:referred_by_id, :referred_to_id], name: 'referrals'
    add_index :contact_referrals, :referred_to_id
  end
end
