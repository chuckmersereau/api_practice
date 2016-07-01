class OrganizationFetcherWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: false, unique: true

  def perform
    # Download the org csv from tnt and update orgs
    organizations = open('https://download.tntware.com/tntconnect/TntConnect_Organizations.csv').read.unpack('C*').pack('U*')
    CSV.new(organizations, headers: :first_row).each do |line|
      next unless line[1].present?

      if org = Organization.find_by(name: line[0])
        org.update(query_ini_url: line[1])
      elsif org = Organization.find_by(query_ini_url: line[1])
        org.update(name: line[0])
      else
        country = guess_country(line[0])
        locale = guess_locale(country)
        org = Organization.create(name: line[0], query_ini_url: line[1], iso3166: line[2],
                                  api_class: 'DataServer', country: country, locale: locale)
      end

      # Grab latest query.ini file for this org
      begin
        uri = URI.parse(org.query_ini_url)
        ini_body = uri.read('r:UTF-8').unpack('C*').pack('U*').force_encoding('UTF-8').encode!
        # remove unicode characters if present
        ini_body = ini_body[3..-1] if ini_body.first.localize.code_points.first == 239

        # ini_body = ini_body[1..-1] unless ini_body.first == '['
        ini = IniParse.parse(ini_body)
        attributes = {}
        attributes[:redirect_query_ini] = ini['ORGANIZATION']['RedirectQueryIni']
        attributes[:abbreviation] = ini['ORGANIZATION']['Abbreviation']
        attributes[:abbreviation] = ini['ORGANIZATION']['Abbreviation']
        attributes[:logo] = ini['ORGANIZATION']['WebLogo-JPEG-470x120']
        attributes[:account_help_url] = ini['ORGANIZATION']['AccountHelpUrl']
        attributes[:minimum_gift_date] = org.minimum_gift_date || ini['ORGANIZATION']['MinimumWebGiftDate']
        attributes[:code] = ini['ORGANIZATION']['Code']
        attributes[:query_authentication] = ini['ORGANIZATION']['QueryAuthentication'].to_i == 1
        attributes[:org_help_email] = ini['ORGANIZATION']['OrgHelpEmail']
        attributes[:org_help_url] = ini['ORGANIZATION']['OrgHelpUrl']
        attributes[:org_help_url_description] = ini['ORGANIZATION']['OrgHelpUrlDescription']
        attributes[:org_help_other] = ini['ORGANIZATION']['OrgHelpOther']
        attributes[:request_profile_url] = ini['ORGANIZATION']['RequestProfileUrl']
        attributes[:staff_portal_url] = ini['ORGANIZATION']['StaffPortalUrl']
        attributes[:default_currency_code] = ini['ORGANIZATION']['DefaultCurrencyCode']
        attributes[:allow_passive_auth] = ini['ORGANIZATION']['AllowPassiveAuth'] == 'True'
        %w(account_balance donations addresses addresses_by_personids profiles designations).each do |section|
          keys = ini.map do |k, _v|
            k.key =~ /^#{section.upcase}[\.\d]*$/ ? k.key : nil
          end.compact.sort.reverse
          keys.each do |k|
            if attributes["#{section}_url"].nil? && ini[k]['Url']
              attributes["#{section}_url"] = ini[k]['Url']
            end
            if attributes["#{section}_params"].nil? && ini[k]['Post']
              attributes["#{section}_params"] = ini[k]['Post']
            end
          end
        end
        begin
          org.update_attributes(attributes)
          Rails.logger.debug "\nSUCCESS: #{org.query_ini_url}\n\n"
        rescue => e
          raise e.message + "\n\n" + attributes.inspect
        end
      rescue => e
        Rails.logger.debug "failed on #{org.query_ini_url}"
        Rails.logger.debug e.message
      end
    end
  end

  def guess_country(org_name)
    org_prefixes = ['Campus Crusade for Christ - ', 'Cru - ', 'Power To Change - ',
                    'Gospel For Asia', 'Agape']
    org_prefixes.each do |prefix|
      org_name = org_name.gsub(prefix, '')
    end
    org_name = org_name.split(' - ').last if org_name.include? ' - '
    org_name = org_name.strip
    return 'Canada' if org_name == 'CAN'
    match = ::CountrySelect::COUNTRIES_FOR_SELECT.find do |country|
      country[:name] == org_name || country[:alternatives].split(' ').include?(org_name)
    end
    return match[:name] if match
    nil
  end

  def guess_locale(country)
    return 'en' unless country.present?
    ISO3166::Country.find_country_by_name(country)&.languages&.first || 'en'
  end
end
