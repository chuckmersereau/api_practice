require 'spec_helper'

describe AccountList::Merge, '#merge' do
  let(:loser) { create(:account_list) }
  let(:winner) { create(:account_list) }

  it 'deletes old AccountList' do
    expect { winner.merge(loser) }.to change(AccountList, :count).by(1)
  end

  it 'moves over users' do
    user = create(:user)
    loser.users << user
    winner.merge(loser)
    expect(winner.users).to include user
  end

  it 'merges appeals' do
    create(:appeal, account_list: loser)
    expect do
      winner.merge(loser)
    end.to change(winner.appeals.reload, :count).by(1)
  end

  it 'moves the prayer letters account from the loser if winner lacked one' do
    create(:prayer_letters_account, account_list: loser)
    winner.merge(loser)
    expect(winner.reload.prayer_letters_account).to_not be_nil
  end

  it 'leaves the winner prayer letter account if both winner and loser have one' do
    create(:prayer_letters_account, account_list: loser)
    winner_pla = create(:prayer_letters_account, account_list: winner)
    expect { winner.merge(loser) }.to change(PrayerLettersAccount, :count).to(1)
    expect(winner.reload.prayer_letters_account).to eq(winner_pla)
  end

  it 'moves designation accounts if they are missing, runs dup balance fix' do
    da = create(:designation_account)
    loser.designation_accounts << da
    expect(winner).to receive(:async).with(:import_data)
    expect(DesignationAccount::DupByBalanceFix)
      .to receive(:deactivate_dups) do |designations|
      expect(designations.to_set).to eq([da].to_set)
      true
    end

    expect do
      winner.merge(loser)
    end.to change(winner.designation_accounts, :count).from(0).to(1)
  end

  it 'does not create a duplicate if a designation account is in both winner and loser' do
    da = create(:designation_account)
    loser.designation_accounts << da
    winner.designation_accounts << da
    winner.reload
    expect(winner.designation_accounts.count).to eq(1)
  end
end
