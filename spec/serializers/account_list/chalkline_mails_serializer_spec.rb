require 'rails_helper'

describe AccountList::ChalklineMailsSerializer do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  subject { AccountList::ChalklineMailsSerializer.new(account_list: account_list).as_json }

  it { should include :id }
  it { should include :created_at }
  it { should include :updated_at }
  it { should include :updated_in_db_at }
end
