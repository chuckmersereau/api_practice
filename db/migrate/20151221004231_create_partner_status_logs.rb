class CreatePartnerStatusLogs < ActiveRecord::Migration
  def change
    create_table :partner_status_logs do |t|
      t.integer :contact_id, null: false
      t.date :recorded_on, null: false

      t.string :status
      t.decimal :pledge_amount
      t.decimal :pledge_frequency
      t.boolean :pledge_received
      t.date :pledge_start_date

      t.timestamps null: false
    end

    add_index :partner_status_logs, :contact_id
    add_index :partner_status_logs, :recorded_on
  end
end
