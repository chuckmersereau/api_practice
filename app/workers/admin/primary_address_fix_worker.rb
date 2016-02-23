class Admin::PrimaryAddressFixWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, retry: false

  def perform(account_list_id)
    AccountList.find(account_list_id).contacts.find_each do |contact|
      Admin::PrimaryAddressFix.new(contact).fix!
    end
  end
end
