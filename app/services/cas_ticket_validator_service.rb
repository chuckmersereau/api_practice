class CasTicketValidatorService
  attr_reader :ticket, :service

  def initialize(ticket:, service:)
    @ticket = ticket
    @service = service
  end

  def validate
    return true if authentication_success?
    raise Exceptions::AuthenticationError, error_message
  end

  def attribute(attribute_name)
    response.dig('serviceResponse', 'authenticationSuccess', 'attributes', attribute_name, '__content__')&.strip
  end

  private

  def authentication_success?
    return true  if response.dig('serviceResponse', 'authenticationSuccess').present?
    return false if response.dig('serviceResponse', 'authenticationFailure').present?
    raise 'Unknown response from /cas/serviceValidate'
  end

  def error_code
    return nil if authentication_success?
    response.dig('serviceResponse', 'authenticationFailure', 'code')
  end

  def error_content
    return nil if authentication_success?
    response.dig('serviceResponse', 'authenticationFailure', '__content__')&.strip
  end

  def error_message
    [error_code, error_content].join(': ')
  end

  def response
    @response ||= ActiveSupport::XmlMini.parse(open_xml)
  end

  def url
    base_url = ENV['CAS_BASE_URL']
    raise('expected CAS_BASE_URL environment variable to be present and using https') unless base_url.present? && base_url.starts_with?('https://')
    "#{base_url}/p3/serviceValidate?ticket=#{ticket}&service=#{service}"
  end

  def open_xml
    open(url)
  end
end
