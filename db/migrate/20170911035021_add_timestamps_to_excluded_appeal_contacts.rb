class AddTimestampsToExcludedAppealContacts < ActiveRecord::Migration
  def change
    add_timestamps :appeal_excluded_appeal_contacts, default: DateTime.now
    change_column_default :appeal_excluded_appeal_contacts, :created_at, nil
    change_column_default :appeal_excluded_appeal_contacts, :updated_at, nil
  end
end
