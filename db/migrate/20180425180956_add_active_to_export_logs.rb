class AddActiveToExportLogs < ActiveRecord::Migration
  def change
    add_column :export_logs, :active, :boolean, default: true
    ExportLog.update_all(active: false)
  end

  class ExportLog < ActiveRecord::Base; end
end
