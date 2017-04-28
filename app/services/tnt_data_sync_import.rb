class TntDataSyncImport
  def initialize(import)
    @import = import
    @account_list = import.account_list
    @user = import.user
    @profile = @account_list.designation_profiles.first || @user.designation_profiles.first
    @data_server = DataServer.new(Person::OrganizationAccount.find(import.source_account_id))
  end

  def import
    raise Import::UnsurprisingImportError unless file_contents_valid?
    @data_server.import_donors_from_csv(@account_list, @profile, section('DONORS'), @user)
    @data_server.import_donations_from_csv(@profile, section('GIFTS'))
    @account_list.send_account_notifications
    false
  end

  private

  def file_contents_valid?
    section('DONORS').present? && section('GIFTS').present?
  end

  def section(heading)
    @import.file.cache_stored_file!
    file_contents = File.open(@import.file_path).read
    @sections_by_heading ||= Hash[file_contents.scan(/^\[(.*?)\]\r?\n(.*?)(?=^\[|\Z)/m)]
    @sections_by_heading[heading].try(:strip)
  end
end
