class AccountListImportDataEnqueuerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_account_list_import_data_enqueuer_worker, unique: :until_executed

  def perform
    AccountList.with_linked_org_accounts.pluck(:id).each do |account_list_id|
      Sidekiq::Client.push(
        'class' => AccountList,
        'args'  => [account_list_id, :import_data],
        'queue' => :api_account_list_import_data
      )
    end
  end
end
