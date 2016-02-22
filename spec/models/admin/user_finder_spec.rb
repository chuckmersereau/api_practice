require 'spec_helper'

describe Admin::UserFinder, '.find_users' do
  it 'finds user by id' do
    user = create(:user)
    expect(Admin::UserFinder.find_users("#{user.id}")).to eq [user]
  end

  it 'finds users by name' do
    # Shouldn't find this non-user person with name
    create(:person, first_name: 'John', last_name: 'Doe')
    john1 = create(:user_with_account, first_name: 'John', last_name: 'Doe')
    john2 = create(:user_with_account, first_name: 'John', last_name: 'Doe')
    create(:user_with_account, first_name: 'Jane', last_name: 'Doe')

    found_users = Admin::UserFinder.find_users('john DOE')

    expect(found_users.to_set).to eq [john1, john2].to_set
  end

  it 'finds user by relay account' do
    account = create(:relay_account, username: 'john@t.co')

    found_user = Admin::UserFinder.find_users('John@T.co').first

    expect(found_user).to be_a User
    expect(found_user.id).to eq account.person.id
  end

  it 'finds user by key account' do
    account = create(:key_account, email: 'john@t.co')

    found_user = Admin::UserFinder.find_users('John@T.co').first

    expect(found_user).to be_a User
    expect(found_user.id).to eq account.person.id
  end

  it 'returns only use result for a user with multiple account lists' do
    john = create(:user_with_account, first_name: 'John', last_name: 'Doe')
    john.account_lists << create(:account_list)

    found_users = Admin::UserFinder.find_users('John Doe')

    expect(found_users).to eq [john]
  end

  it 'can look up by "Last Name, First Name"' do
    john = create(:user_with_account, first_name: 'Mary Lou', last_name: 'Doe Nut')
    john.account_lists << create(:account_list)

    found_users = Admin::UserFinder.find_users('Doe Nut, Mary Lou')

    expect(found_users).to eq [john]
  end
end
