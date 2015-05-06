class TntDataSyncImport
  def initialize(import)
    @import = import
    @account_list = import.account_list
    @user = import.user
    @profile = @account_list.designation_profiles.first || @user.designation_profiles.first
    @data_server = DataServer.new(Person::OrganizationAccount.find(import.source_account_id))
  end

  def import
    fail Import::UnsurprisingImportError unless @import.file_contents.starts_with?('[ORGANIZATION]')
    @data_server.import_donors_from_csv(@account_list, @profile, section('DONORS'), @user)
    @data_server.import_donations_from_csv(@profile, section('GIFTS'))
  end

  private

  def section(heading)
    @sections_by_heading ||= Hash[@import.file_contents.scan(/^\[(.*?)\]\r?\n(.*?)(?=^\[|\Z)/m)]
    @sections_by_heading[heading].strip
  end
end
