class User::Coach < User
  has_many :coaching_account_lists, -> { uniq }, through: :account_list_coaches, source: :account_list
  has_many :coaching_contacts, -> { uniq }, through: :coaching_account_lists, source: :contacts
  has_many :coaching_pledges, -> { uniq }, through: :coaching_account_lists, source: :pledges

  def remove_coach_access(account_list)
    account_list_coaches.where(account_list: account_list).destroy_all
  end
end
