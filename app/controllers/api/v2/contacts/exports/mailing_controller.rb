require 'csv'

class Api::V2::Contacts::Exports::MailingController < Api::V2::Contacts::ExportsController
  supports_accept_header_content_types :any
  supports_content_types :any
  resource_type 'export_logs'

  protected

  def export_log_type
    'Contacts Mailing'
  end

  def render_csv(filename)
    headers['Content-Type'] ||= 'text/csv'
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render text: CsvExport.mailing_addresses(@contacts), filename: filename
  end
end
