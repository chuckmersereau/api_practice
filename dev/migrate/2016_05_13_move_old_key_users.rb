class OldKeyAccount < ActiveRecord::Base
  self.table_name = 'person_key_accounts'
end

def move_over_old_key_user_data
  OldKeyAccount.find_each do |old_key_account|
    puts "Key account: #{old_key_account.id}"
    relay_account = Person::RelayAccount.find_by('upper(remote_id) = ?',
                                                 old_key_account.remote_id.upcase)
    if relay_account.nil?
      puts "No existing Person::RelayAccount for old key account #{old_key_account.id}"
      next
    end
    next if relay_account.person_id == old_key_account.person_id

    old_user = User.find(old_key_account.person_id)
    new_user = User.find(relay_account.person_id)
    move_user_data(from_user: old_user, to_user: new_user)
  end
end
