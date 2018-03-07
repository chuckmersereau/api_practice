class DataServerUk < DataServer
  def import_profile_balance(profile)
    check_credentials!

    balance = profile_balance(profile.code)
    attributes = { balance: balance[:balance], balance_updated_at: balance[:date] }
    profile.update_attributes(attributes)

    return unless balance[:designation_numbers]
    attributes[:name] = balance[:account_names].first if balance[:designation_numbers].length == 1
    balance[:designation_numbers].each_with_index do |number, _i|
      find_or_create_designation_account(number, profile, attributes)
    end
  end
end
