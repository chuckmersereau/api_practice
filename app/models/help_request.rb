require 'user_agent_decoder'

class HelpRequest < ActiveRecord::Base
  mount_uploader :file, HelpRequestUploader

  attr_accessor :user_agent

  after_commit :send_email

  belongs_to :account_list
  belongs_to :user

  serialize :session, JSON
  serialize :user_preferences, JSON
  serialize :account_list_preferences, JSON

  validates :name, :email, :problem, :request_type, presence: true
  validates :email, email: true

  def send_email
    HelpRequestMailer.email(self).deliver
  end

  def user_agent=(val)
    @user_agent = val
    self.browser = parse_browser(val)
  end

  def self.attachment_token(id)
    message_verifier.generate(id)
  end

  def self.decrypt_token(signed_message)
    message_verifier.verify(signed_message)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
  end

  def self.message_verifier
    @message_verifier ||= ActiveSupport::MessageVerifier.new(ENV.fetch('ATTACHMENT_SECRET'))
  end

  private

  def parse_browser(user_agent)
    return '' unless user_agent
    decoder = UserAgentDecoder.new(user_agent).parse
    decoder[:browser][:name] + ' ' + decoder[:browser][:version]
  end
end
