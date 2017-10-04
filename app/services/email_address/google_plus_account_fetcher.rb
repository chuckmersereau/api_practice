require 'net/http'

class EmailAddress::GooglePlusAccountFetcher
  attr_accessor :email_address

  def initialize(email_address)
    @email_address = email_address
  end

  def fetch_google_plus_account
    google_plus_json_object = fetch_google_plus_json_object

    return unless google_plus_json_object

    GooglePlusAccount.new(account_id: google_plus_json_object.dig('gphoto$user', '$t'),
                          profile_picture_link: google_plus_json_object.dig('gphoto$thumbnail', '$t'))
  end

  private

  def fetch_google_plus_json_object
    uri = URI("https://picasaweb.google.com/data/entry/api/user/#{email_address.email}?alt=json")

    response = Net::HTTP.get(uri)

    JSON.parse(response)
  rescue JSON::ParserError
    nil
  end
end
