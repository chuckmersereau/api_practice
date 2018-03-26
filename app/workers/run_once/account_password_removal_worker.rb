class RunOnce::AccountPasswordRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_run_once

  def perform
    accounts_with_tokens.find_each do |oa|
      next unless oa.valid?
      oa.update_columns(username: nil, password: nil)
    end
  end

  private

  def accounts_with_tokens
    Person::OrganizationAccount.where.not(token: nil)
  end
end
