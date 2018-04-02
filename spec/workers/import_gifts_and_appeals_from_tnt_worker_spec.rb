require 'rails_helper'

describe ImportGiftsAndAppealsFromTntWorker do
  let!(:appeal) { create(:appeal) }
  let!(:account_list) { appeal.account_list }
  let!(:user) { create(:user).tap { |user| account_list.users << user } }
  let!(:organization_account) { create(:organization_account, person: user) }
  let!(:import) { create(:tnt_import_campaigns_and_promises, account_list: account_list) }
  let!(:worker) { ImportGiftsAndAppealsFromTntWorker.new }

  before do
    stub_smarty_streets
  end

  it 'sends the message to run the import' do
    expect(worker).to receive(:perform_import)
    worker.perform(import.id)
  end

  it 'does not import if the source is not tnt' do
    import.update_columns(source: 'csv')
    expect(worker).to_not receive(:perform_import)
    worker.perform(import.id)
  end

  it 'does not import if the account list does not exist' do
    account_list.delete
    expect(worker).to_not receive(:perform_import)
    worker.perform(import.id)
  end

  it 'does not import if the account has no appeals' do
    appeal.delete
    expect(worker).to_not receive(:perform_import)
    worker.perform(import.id)
  end

  it 'imports appeals, pledges, and gifts' do
    expect_any_instance_of(TntImport::AppealsImport).to receive(:import)
    expect_any_instance_of(TntImport::PledgesImport).to receive(:import)
    expect_any_instance_of(TntImport::GiftsImport).to receive(:import)
    worker.perform(import.id)
  end

  it 'imports appeals with expected parameters' do
    appeal = create(:appeal, tnt_id: 183_362_175)
    account_list.appeals << appeal
    contact = create(:contact)
    account_list.contacts << contact
    appeal.contacts << contact # Add a contact to the appeal to test that it shows up in the arguments below.
    tnt_import = TntImport.new(import)
    expect(worker).to receive(:tnt_import).and_return(tnt_import)
    expect(TntImport::AppealsImport).to receive(:new).with(account_list,
                                                           { '183362175' => [contact.id], '291896527' => [],
                                                             '681505203' => [], '830704017' => [],
                                                             '936046261' => [], '936046262' => [],
                                                             '1494330654' => [], '1541020410' => [] },
                                                           tnt_import.xml).and_return(double(import: true))
    worker.perform(import.id)
  end

  it 'imports pledges with expected parameters' do
    tnt_import = TntImport.new(import)
    expect(worker).to receive(:tnt_import).and_return(tnt_import)
    expect(TntImport::PledgesImport).to receive(:new)
      .with(account_list, import, tnt_import.xml)
      .and_return(double(import: true))
    worker.perform(import.id)
  end

  it 'imports gifts with expected parameters' do
    tnt_import = TntImport.new(import)
    contact = create(:contact, tnt_id: 1)
    # Add a contact to the account_list to test that it shows up in the arguments below.
    account_list.contacts << contact
    expect(worker).to receive(:tnt_import).and_return(tnt_import)
    expect(TntImport::GiftsImport).to receive(:new)
      .with(account_list, { '1' => contact.id }, tnt_import.xml, import)
      .and_return(double(import: true))
    worker.perform(import.id)
  end
end
