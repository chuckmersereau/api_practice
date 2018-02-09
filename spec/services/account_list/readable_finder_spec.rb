require 'rails_helper'

describe AccountList::ReadableFinder do
  let(:coach) { create(:user_with_account).becomes(User::Coach) }
  let(:coach_id) { coach.id }
  subject { AccountList::ReadableFinder.new(coach) }

  let(:coached_user) { create :user_with_account }

  let(:account_list) { coach.account_lists.first }
  let(:coached_account_list) { coached_user.account_lists.first }
  let(:uncoached_account_list) do
    create(:account_list).tap do |account_list|
      coached_user.account_lists << account_list
    end
  end

  it 'generates the correct SQL' do
    expect(subject.to_sql).to eq(
      '"account_lists"."id" IN (SELECT "account_lists"."id" FROM ' \
      '"account_lists" LEFT OUTER JOIN "account_list_coaches" ON ' \
      '"account_lists"."id" = "account_list_coaches"."account_list_id"' \
      ' LEFT OUTER JOIN "account_list_users" ON "account_lists"."id" =' \
      ' "account_list_users"."account_list_id" WHERE ' \
      "(\"account_list_users\".\"user_id\" = '#{coach_id}' OR " \
      "\"account_list_coaches\".\"coach_id\" = '#{coach_id}'))"
    )
  end

  it 'returns owned account_lists' do
    expect(subject.relation.to_a).to eq [account_list]
  end

  it 'returns coached account_lists' do
    coach.update!(account_lists: [],
                  coaching_account_lists: [coached_account_list])

    expect(subject.relation.to_a).to eq [coached_account_list]
  end

  it 'returns coached and owned account_lists' do
    coach.update!(coaching_account_lists: [coached_account_list])

    expect(subject.relation.to_a).to include account_list, coached_account_list
  end

  it 'returns coached and owned account_lists' do
    coach.update!(coaching_account_lists: [coached_account_list])

    expect(subject.relation.to_a).not_to include uncoached_account_list
  end
end
