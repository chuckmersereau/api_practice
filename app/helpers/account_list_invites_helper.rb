module AccountListInvitesHelper
  def account_list_invite_url(invite)
    "#{url_protocol}#{root_url}/account_lists/#{invite.account_list.uuid}/accept_invite/#{invite.uuid}?code=#{invite.code}"
  end

  def root_url
    Rails.application.routes.default_url_options[:host]
  end

  def url_protocol
    Rails.env.development? ? 'http://' : 'https://'
  end
end
