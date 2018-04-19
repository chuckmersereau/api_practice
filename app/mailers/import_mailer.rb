class ImportMailer < ApplicationMailer
  layout 'inky'

  def success(import, successes = nil)
    user = import.user
    return unless user&.email
    @import = import
    @successes = successes
    I18n.locale = user.locale || 'en'

    subject = _('[MPDX] Importing your %{source} contacts completed')
    mail(to: user.email, subject: format(subject, source: import.user_friendly_source))
  end

  def failed(import, successes = nil, failures = nil)
    user = import.user
    return unless user&.email
    @import = import
    @successes = successes
    @failures = failures
    I18n.locale = user.locale || 'en'
    @explanation = failure_explanation
    attachments[failure_attachment_filename] = failure_attachment if failure_attachment.present?

    subject = _('[MPDX] Importing your %{source} contacts failed')
    mail(to: user.email, subject: format(subject, source: import.user_friendly_source))
  end

  def credentials_error(account)
    user = account.person
    return unless user&.email
    @account = account

    subject = _('[MPDX] Your credentials for %{source} are invalid')
    mail(to: user.email, subject: format(subject, source: account.organization.name))
  end

  private

  def failure_explanation
    case @import.source
    when 'tnt', 'tnt_data_sync'
      _('There are a number of reasons an import can fail. The most common reason is a temporary '\
      'server issue. Please try your import again. If it fails again, send an email to support@mpdx.org '\
      "with your Tnt export attached. Having the file you're trying to import will greatly "\
      'help us in trying to determine why the import failed.')
    when 'csv'
      _('There are a number of reasons an import can fail. The most likely reason for a CSV import '\
      'to fail is due to First Name. First Name is a required field on CSV import. We have attached '\
      'a CSV file to this email containing the rows that failed to import. The first column in this '\
      'CSV contains an error message about that row. Please download this CSV, fix the issues '\
      'inside it, and then try to import it again. You do not need to reimport the contacts that '\
      'were successfully imported previously. If it fails again, send us an email at support@mpdx.org '\
      'and we will investigate what went wrong.')
    when 'facebook'
      _('There are a number of reasons an import can fail. Often the failure is a temporary issue '\
      'with Facebook that is outside of our control. Please try your import again. '\
      'If it fails again, send us an email at support@mpdx.org and we will investigate what went wrong.')
    else
      _('There are a number of reasons an import can fail. Often the failure '\
      'can be a temporary network issue. Please try your import again. '\
      'If it fails again, send us an email at support@mpdx.org and we will investigate what went wrong.')
    end
  end

  def failure_attachment
    return unless @import.source_csv? && @import.file_row_failures.present?
    @failure_attachment ||= CsvImport.new(@import).generate_csv_from_file_row_failures
  end

  def failure_attachment_filename
    return unless @import.source_csv?
    'MPDX Import Failures.csv'
  end
end
