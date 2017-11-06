# The purpose of this worker is to help transition DataSever user credentials from username/password to access tokens.
# This worker will not work after August 1, 2018. This worker is for transitional use only.
require 'csv'

class ConvertCredentialsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_convert_credentials_worker

  def perform
    Person::OrganizationAccount
      .joins(:organization)
      .where('person_organization_accounts.token IS NULL AND organizations.oauth_convert_to_token_url IS NOT NULL')
      .find_each do |organization_account|
      convert(organization_account)
    end
  end

  protected

  def convert(organization_account)
    url = organization_account.organization.oauth_convert_to_token_url
    params = params(organization_account)
    response = get_response(url, params)
    CSV.new(response, headers: :first_row, header_converters: ->(h) { h.underscore }).each do |line|
      organization_account.update(username: nil, password: nil, token: line['token']) if line['token']
    end
  rescue => ex
    Rollbar.error(ex, organization_account_id: organization_account.id)
  end

  def params(organization_account, params = {})
    params['UserName'] = organization_account.username
    params['Password'] = organization_account.password
    params['Action'] = 'OAuthConvertToToken'
    params['client_id'] = ENV.fetch('DONORHUB_CLIENT_ID')
    params['client_secret'] = ENV.fetch('DONORHUB_CLIENT_SECRET')
    params['client_instance'] = 'app'
    params
  end

  def get_response(url, params)
    RestClient::Request.execute(method: :post, url: url, payload: params) do |response|
      EncodingUtil.normalized_utf8(response.to_str)
    end
  end
end
