class NewUserTransferWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_default, unique: :until_executed

  def perform(user_id)
    user = User.find(user_id)
    return unless user
    RowTransferRequest.transfer(MasterPerson, user.master_person.uuid, safe: false) if user.master_person
    RowTransferRequest.transfer(User, user.uuid)
  end
end
