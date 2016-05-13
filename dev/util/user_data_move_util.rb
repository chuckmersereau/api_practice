def move_user_data(from_user:, to_user:)
  UserDataMover.new(from_user: from_user, to_user: to_user).move_data
end

class UserDataMover
  def initialize(from_user:, to_user:)
    @from_user = from_user
    @to_user = to_user
  end

  def move_data
    puts "Moving data for user #{from_user.id} into user #{to_user.id} ..."
    move_imports
    move_invites
    move_google_accounts
    move_org_accounts
    move_designation_profiles
    move_account_lists
    orphan_empty_account_lists
    puts "Moved data for user #{from_user.id} into user #{to_user.id}"
  end

  private

  attr_reader :from_user, :to_user

  def move_imports
    from_user.imports.each do |import|
      puts "  Moving import #{import.id} from #{from_user.id} to #{to_user.id}"
      import.update_column(:user_id, to_user.id)
    end
  end

  def move_invites
    AccountListInvite.where(invited_by_user: from_user).each do |invite|
      puts "  Moving invited_by #{invite.id} from #{from_user.id} to #{to_user.id}"
      invite.update(invited_by_user: to_user)
    end
    AccountListInvite.where(accepted_by_user: from_user).each do |invite|
      puts "  Moving acceptd_by #{invite.id} from #{from_user.id} to #{to_user.id}"
      invite.update(accepted_by_user: to_user)
    end
    AccountListInvite.where(cancelled_by_user: from_user).each do |invite|
      puts "  Moving canceled_by #{invite.id} from #{from_user.id} to #{to_user.id}"
      invite.update(cancelled_by_user: to_user)
    end
  end

  def move_google_accounts
    from_user.google_accounts.each do |google_account|
      next if google_account.email.in?(to_user.google_accounts.pluck(:email))
      puts "  Moving Google account #{google_account.id} from #{from_user.id} to #{to_user.id}"
      google_account.update(person: to_user)
    end
  end

  def move_org_accounts
    from_user.organization_accounts.each do |org_account|
      next if org_account.organization_id.in?(to_user.organization_accounts.pluck(:organization_id))
      puts "  Moving org account #{org_account.id} from #{from_user.id} to #{to_user.id}"
      org_account.update(person: to_user)
    end
  end

  def move_designation_profiles
    from_user.designation_profiles.each do |dp|
      next if dp.in?(to_user.designation_profiles)
      puts "  Adding designation profile #{dp.id} to #{to_user.id}"
      to_user.designation_profiles << dp
    end
  end

  def move_account_lists
    from_user.account_lists.each do |account_list|
      next if account_list.contacts.empty?
      next if account_list.in?(to_user.account_lists)
      puts "  Adding account #{account_list.id} to #{to_user.id}"
      to_user.account_lists << account_list
    end
  end

  def orphan_empty_account_lists
    if to_user.account_lists.present?
      to_user.account_lists.each do |account_list|
        next if account_list.contacts.present?
        puts "  Orphaning empty account list #{account_list.id} for #{to_user.id}"
        to_user.account_list_users.where(account_list: account_list).each(&:destroy)
      end
    end
  end
end
