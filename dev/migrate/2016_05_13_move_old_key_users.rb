class OldKeyAccount < ActiveRecord::Base
  self.table_name = 'person_key_accounts'
end

def move_over_old_key_user_data
  OldKeyAccount.find_each do |old_key_account|
    relay_account = Person::RelayAccount.find_by(remote_id: key_account.remote_id)
    next if relay_account.person_id == old_key_account.person_id

    old_user = User.find(old_key_account.person_id)
    new_user = User.find(relay_account.person_id)
    move_user_data(from_user: old_user, to_user: new_user)
  end
end
