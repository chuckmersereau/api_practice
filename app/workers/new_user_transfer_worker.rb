class NewUserTransferWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_default, unique: :until_executed

  def perform(user_id)
    user = User.find(user_id)
    RowTransferRequest.transfer(User, user_id) if user
  end
end
