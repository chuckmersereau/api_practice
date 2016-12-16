class AddUuidToPartnerStatusLogs < ActiveRecord::Migration
  def change
    add_column :partner_status_logs, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :partner_status_logs, :uuid, unique: true
  end
end
