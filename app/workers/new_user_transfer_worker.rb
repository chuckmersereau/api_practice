class NewUserTransferWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_default, unique: :until_executed

  def perform(user_id)
    return if NewUserTransferWorker.disabled?
    user = User.find(user_id)
    return unless user
    RowTransferRequest.transfer(MasterPerson, user.master_person.id, safe: false) if user.master_person
    RowTransferRequest.transfer(User, user.id)
  end

  def self.perform_async(user_id)
    super(user_id) unless disabled?
  end

  def self.disabled?
    ENV['KIRBY_URL'].blank? || ENV['DISABLE_KIRBY'] == 'true'
  end
end
