module MpdxHelpers
  def api_login(user)
    allow_any_instance_of(Api::V2Controller).to receive(:jwt_authorize!)
    allow_any_instance_of(Api::V2Controller).to receive(:current_user).and_return(user)
  end

  def api_logout
    allow_any_instance_of(Api::V2Controller).to receive(:jwt_authorize!).and_raise(Exceptions::AuthenticationError)
    allow_any_instance_of(Api::V2Controller).to receive(:current_user).and_return(nil)
  end

  def login(user)
    # rubocop:disable Style/GlobalVars
    $request_test = true
    $user = user
    # rubocop:enable Style/GlobalVars
  end

  def stub_google_geocoder
    stub_request(:get, %r{maps\.googleapis\.com/maps/api.*}).to_return(body: '{}')
  end

  def stub_smarty_streets
    stub_request(:get, %r{https://api\.smartystreets\.com/street-address/.*})
      .to_return(body: '[]')
  end

  # Clear out unique job locks. They can get into Redis if you interrupt a test
  # run or don't call Worker.clear after queuing jobs in a spec.
  def clear_uniqueness_locks
    Sidekiq.redis do |redis|
      redis.keys('*unique*').each { |k| redis.del(k) }
    end
  end

  # locally, the orgs are seeded if you run rake db:test:prepare, but in
  # Travis the database is fully empty since it just loads structure.sql
  def org_for_code(code)
    Organization.find_by(code: code) ||
      create(:organization, name: code, code: code)
  end

  def stub_auth
    stub_request(:get, 'http://oauth.ccci.us/users/' + user.access_token)
      .to_return(status: 200)
  end

  def expect_delayed_email(mailer, mailing_method)
    delayed = double
    expect(mailer).to receive(:delay).and_return(delayed)
    expect(delayed).to receive(mailing_method)
  end
end
