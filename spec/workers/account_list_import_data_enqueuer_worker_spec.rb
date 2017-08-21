require 'rails_helper'

describe AccountListImportDataEnqueuerWorker do
  let!(:first_user) { create(:user_with_full_account) }
  let!(:first_account_list) { first_user.account_lists.first }

  let!(:second_user) { create(:user_with_full_account) }
  let!(:second_account_list) { second_user.account_lists.first }

  let!(:account_list_without_org_account) { create(:account_list) }

  it 'queues the jobs' do
    expect(Sidekiq::Client).to receive(:push).with(
      'class' => AccountList,
      'args'  => [first_account_list.id, :import_data],
      'queue' => :api_account_list_import_data
    ).once

    expect(Sidekiq::Client).to receive(:push).with(
      'class' => AccountList,
      'args'  => [second_account_list.id, :import_data],
      'queue' => :api_account_list_import_data
    ).once

    expect(Sidekiq::Client).to_not receive(:push).with(
      'class' => AccountList,
      'args'  => [account_list_without_org_account.id, :import_data],
      'queue' => :api_account_list_import_data
    )

    AccountListImportDataEnqueuerWorker.new.perform
  end
end
