class TntDataSyncImport
  def initialize(import)
    @import = import
    @account_list = @import.account_list
    @user = @import.user
    @designation_profile = @account_list.designation_profiles.first || @user.designation_profiles.first
  end

  def import
    STDERR.puts "did import!"
  end
end
