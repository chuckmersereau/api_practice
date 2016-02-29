class Admin::AccountPrimaryAddressesFix
  def initialize(account_list)
    @account_list = account_list
  end

  def fix
    @account_list.contacts.find_each(&method(:fix_contact))
  end

  private

  def fix_contact(contact)
    Admin::PrimaryAddressFix.new(contact).fix
  end
end
