RSpec.configure do |config|
  config.before(:suite) do
    $stdout.puts('Stubbing all calls to the #start_google_plus_account_fetcher_job on EmailAddress create')
  end

  config.before(:each) do
    allow_any_instance_of(EmailAddress).to receive(:start_google_plus_account_fetcher_job)
  end
end
