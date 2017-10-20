class OrganizationFromQueryUrlWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_organization_from_query_url_worker, unique: :until_executed

  SECTIONS = %w(account_balance donations addresses addresses_by_personids profiles).freeze

  attr_accessor :name, :query_ini_url

  def perform(name, query_ini_url)
    @name = name
    @query_ini_url = query_ini_url
    load_organization
    build_organization
    save_organization
  end

  private

  def load_organization
    @organization ||= Organization.find_by('name = ? OR query_ini_url = ?', name, query_ini_url)
  end

  def build_organization
    @organization ||= Organization.new(iso3166: nil, api_class: 'DataServer')
    @organization.attributes = organization_params
  end

  def save_organization
    @organization.save
    Rails.logger.debug "\nSUCCESS: #{@organization.query_ini_url}\n\n"
  rescue => ex
    Rollbar.error(ex,
                  organization_params: organization_params)
  end

  def organization_params
    return @organization_params if @organization_params
    @organization_params = {}
    @organization_params.merge(organization_attributes)
    @organization_params.merge(section_attributes)
    @organization_params
  end

  def organization_attributes
    {
      name: name,
      query_ini_url: query_ini_url,
      redirect_query_ini: ini['ORGANIZATION']['RedirectQueryIni'],
      abbreviation: ini['ORGANIZATION']['Abbreviation'],
      logo: ini['ORGANIZATION']['WebLogo-JPEG-470x120'],
      account_help_url: ini['ORGANIZATION']['AccountHelpUrl'],
      minimum_gift_date: org.minimum_gift_date || ini['ORGANIZATION']['MinimumWebGiftDate'],
      code: ini['ORGANIZATION']['Code'],
      query_authentication: ini['ORGANIZATION']['QueryAuthentication'].to_i == 1,
      org_help_email: ini['ORGANIZATION']['OrgHelpEmail'],
      org_help_url: ini['ORGANIZATION']['OrgHelpUrl'],
      org_help_url_description: ini['ORGANIZATION']['OrgHelpUrlDescription'],
      org_help_other: ini['ORGANIZATION']['OrgHelpOther'],
      request_profile_url: ini['ORGANIZATION']['RequestProfileUrl'],
      staff_portal_url: ini['ORGANIZATION']['StaffPortalUrl'],
      default_currency_code: ini['ORGANIZATION']['DefaultCurrencyCode'],
      allow_passive_auth: ini['ORGANIZATION']['AllowPassiveAuth'] == 'True'
    }
  end

  def section_attributes(section_attributes = {})
    SECTIONS.each do |section|
      keys = ini.map do |k, _v|
        k.key =~ /^#{section.upcase}[\.\d]*$/ ? k.key : nil
      end.compact.sort.reverse
      keys.each do |k|
        if section_attributes["#{section}_url"].nil? && ini[k]['Url']
          section_attributes["#{section}_url"] = ini[k]['Url']
        end
        if section_attributes["#{section}_params"].nil? && ini[k]['Post']
          section_attributes["#{section}_params"] = ini[k]['Post']
        end
      end
    end
    section_attributes
  end

  def ini
    return @ini if @ini
    uri = URI.parse(query_ini_url)
    ini_body = uri.read('r:UTF-8').unpack('C*').pack('U*').force_encoding('UTF-8').encode!
    # remove unicode characters if present
    ini_body = ini_body[3..-1] if ini_body.first.localize.code_points.first == 239
    @ini = IniParse.parse(ini_body)
  end
end
