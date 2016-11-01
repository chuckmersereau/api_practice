require 'sidekiq/testing'
require 'sidekiq_unique_jobs/testing'

Sidekiq::Logging.logger = nil

RSpec.configure do |config|
  config.before(:each) do |example|
    # Clears out the jobs for tests using the fake testing
    Sidekiq::Worker.clear_all

    if example.metadata[:sidekiq] == :fake
      Sidekiq::Testing.fake!
    elsif example.metadata[:sidekiq] == :testing_disabled
      Sidekiq::Testing.disable!
    elsif example.metadata[:sidekiq] == :acceptance
      Sidekiq::Testing.inline!
    elsif example.metadata[:type] == :acceptance
      Sidekiq::Testing.inline!
    else
      Sidekiq::Testing.fake!
    end
  end
end
