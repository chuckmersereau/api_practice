class OrganizationFromQueryUrlWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_organization_from_query_url_worker, unique: :until_executed

  PREFIXES = ['Campus Crusade for Christ - ', 'Cru - ', 'Power To Change - ', 'Gospel For Asia', 'Agape'].freeze
  SECTIONS = %w(account_balance donations addresses addresses_by_personids profiles).freeze

  attr_accessor :name, :url

  def perform(name, url)
    @name = name
    @url = url
    @organization = find_or_create_organization_by_name_or_url
    update_organzation_attributes_from_query_ini_url
  end

  private

  def find_or_create_organization_by_name_or_url
    organization ||= find_organization_by_name
    organization ||= find_organization_by_url
    organization || create_organization
  end

  def find_organization_by_name
    org = Organization.find_by(name: name)
    return unless org
    org.update(query_ini_url: url)
    org
  end

  def find_organization_by_url
    org = Organization.find_by(query_ini_url: url)
    return unless org
    org.update(name: name)
    org
  end

  def create_organization
    country_name = guess_country(name)
    locale = guess_locale(country_name)
    Organization.create(name: name, query_ini_url: url, iso3166: nil,
                        api_class: 'DataServer', country: country_name, locale: locale)
  end

  def guess_country
    country_name = remove_prefixes_from_name(name)
    country_name = remove_dashes_from_name(country_name)
    country_from_name(country_name)
  end

  def remove_prefixes_from_name(country_name)
    PREFIXES.each do |prefix|
      country_name = country_name.gsub(prefix, '')
    end
    country_name
  end

  def remove_dashes_from_name(country_name)
    country_name = country_name.split(' - ').last if country_name.include? ' - '
    country_name.strip
  end

  def country_from_name(name)
    return 'Canada' if name == 'CAN'
    ::CountrySelect::COUNTRIES_FOR_SELECT.find do |country|
      country[:name] == name || country[:alternatives].split(' ').include?(name)
    end.try(:[], :name)
  end

  def guess_locale(country_name)
    return 'en' unless country_name.present?
    ISO3166::Country.find_country_by_name(country_name)&.languages&.first || 'en'
  end

  def update_organzation_attributes_from_query_ini_url
    @organization.update_attributes(attributes)
    Rails.logger.debug "\nSUCCESS: #{@organization.query_ini_url}\n\n"
  rescue => e
    Rails.logger.debug "\nFAILURE: #{@organization.query_ini_url}\n\n"
    Rails.logger.debug e.message
    Rails.logger.debug attributes.inspect
  end

  def attributes
    return @attributes if @attributes
    @attributes = {}
    organization_attributes
    section_attributes
    @attributes
  end

  def organization_attributes
    @attributes[:redirect_query_ini] = ini['ORGANIZATION']['RedirectQueryIni']
    @attributes[:abbreviation] = ini['ORGANIZATION']['Abbreviation']
    @attributes[:abbreviation] = ini['ORGANIZATION']['Abbreviation']
    @attributes[:logo] = ini['ORGANIZATION']['WebLogo-JPEG-470x120']
    @attributes[:account_help_url] = ini['ORGANIZATION']['AccountHelpUrl']
    @attributes[:minimum_gift_date] = org.minimum_gift_date || ini['ORGANIZATION']['MinimumWebGiftDate']
    @attributes[:code] = ini['ORGANIZATION']['Code']
    @attributes[:query_authentication] = ini['ORGANIZATION']['QueryAuthentication'].to_i == 1
    @attributes[:org_help_email] = ini['ORGANIZATION']['OrgHelpEmail']
    @attributes[:org_help_url] = ini['ORGANIZATION']['OrgHelpUrl']
    @attributes[:org_help_url_description] = ini['ORGANIZATION']['OrgHelpUrlDescription']
    @attributes[:org_help_other] = ini['ORGANIZATION']['OrgHelpOther']
    @attributes[:request_profile_url] = ini['ORGANIZATION']['RequestProfileUrl']
    @attributes[:staff_portal_url] = ini['ORGANIZATION']['StaffPortalUrl']
    @attributes[:default_currency_code] = ini['ORGANIZATION']['DefaultCurrencyCode']
    @attributes[:allow_passive_auth] = ini['ORGANIZATION']['AllowPassiveAuth'] == 'True'
  end

  def section_attributes
    SECTIONS.each do |section|
      keys = ini.map do |k, _v|
        k.key =~ /^#{section.upcase}[\.\d]*$/ ? k.key : nil
      end.compact.sort.reverse
      keys.each do |k|
        if @attributes["#{section}_url"].nil? && ini[k]['Url']
          @attributes["#{section}_url"] = ini[k]['Url']
        end
        if @attributes["#{section}_params"].nil? && ini[k]['Post']
          @attributes["#{section}_params"] = ini[k]['Post']
        end
      end
    end
  end

  def ini
    return @ini if @ini
    uri = URI.parse(@organization.query_ini_url)
    ini_body = uri.read('r:UTF-8').unpack('C*').pack('U*').force_encoding('UTF-8').encode!
    # remove unicode characters if present
    ini_body = ini_body[3..-1] if ini_body.first.localize.code_points.first == 239
    @ini = IniParse.parse(ini_body)
  end
end
