class AccountList::FromProfileLinker
  def initialize(profile, org_account)
    @profile = profile
    @org_account = org_account
  end

  def link_account_list!
    # look for an existing account list with the same designation numbers in it
    # otherwise create a new account list for this profile
    account_list =
      account_from_designation_numbers ||
      AccountList.find_or_create_by!(name: profile.name, creator_id: user.id)

    add_designations(account_list)
    add_user(account_list)
  end

  private

  attr_reader :profile, :org_account
  delegate :user, to: :org_account

  def account_from_designation_numbers
    organization = org_account.organization
    designation_numbers = profile.designation_accounts.map(&:designation_number)
    AccountList::FromDesignationsFinder.new(designation_numbers, organization)
      .account_list
  end

  def add_designations(account_list)
    profile.designation_accounts.each do |da|
      next if account_list.designation_accounts.include?(da)
      account_list.designation_accounts << da
    end
  end

  def add_user(account_list)
    account_list.users << user unless account_list.users.include?(user)
    profile.update(account_list_id: account_list.id)
  end
end
