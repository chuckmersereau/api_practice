# Handles routes to the frontend web client. These routes are typically used in mailers.

class WebRouter
  def self.env
    Rails.env
  end

  def self.protocol
    env == 'development' ? 'http' : 'https'
  end

  def self.host
    case env
    when 'development'
      'localhost:8080'
    when 'staging'
      'stage.mpdx.org'
    else
      'mpdx.org'
    end
  end

  def self.base_url
    "#{protocol}://#{host}"
  end

  def self.account_list_invite_url(invite)
    "#{base_url}/account_lists/#{invite.account_list.uuid}/accept_invite/#{invite.uuid}?code=#{invite.code}"
  end

  def self.integration_preferences_url(integration_name)
    "#{base_url}/preferences/integrations?selectedTab=#{integration_name}"
  end

  def self.notifications_preferences_url
    "#{base_url}/preferences/notifications"
  end

  def self.contact_url(contact)
    "#{base_url}/contacts/#{contact.uuid}"
  end

  def self.person_url(person)
    "#{base_url}/contacts/#{person.contact.uuid}?personId=#{person.uuid}"
  end
end
