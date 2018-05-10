require 'csv'
require 'erb'

class DataServer
  delegate :requires_credentials?, to: :class
  attr_accessor :org, :org_account

  include ERB::Util

  KNOWN_DIFFERING_IMPORT_PERSON_TYPES = [
    'I', # Navigators
  ].freeze

  def self.requires_credentials?
    true
  end

  def initialize(org_account)
    @org_account = org_account
    @org = org_account.organization
  end

  def import_all(date_from)
    Rails.logger.debug 'Importing Profiles'
    designation_profiles = import_profiles
    designation_profiles.each do |p|
      Rails.logger.debug 'Importing Donors'
      import_donors(p, date_from)
      Rails.logger.debug 'Importing Donations'
      import_donations(p, date_from)
    end
  end

  def import_profiles
    designation_profiles = org.designation_profiles.where(user_id: org_account.person_id)

    if org.profiles_url.present?
      check_credentials!

      profiles.each do |profile|
        Retryable.retryable do
          designation_profile =
            org.designation_profiles.where(
              user_id: org_account.person_id,
              name: profile[:name],
              code: profile[:code]
            ).first_or_create
          import_profile_balance(designation_profile)
          AccountList::FromProfileLinker.new(designation_profile, org_account)
                                        .link_account_list! unless designation_profile.account_list
        end
      end
    else
      # still want to update balance if possible
      designation_profiles.each do |designation_profile|
        Retryable.retryable do
          import_profile_balance(designation_profile)
          AccountList::FromProfileLinker.new(designation_profile, org_account)
                                        .link_account_list! unless designation_profile.account_list
        end
      end
    end

    designation_profiles.reload
  end

  def import_donors(profile, date_from = nil)
    check_credentials!
    date_from = date_from.strftime('%m/%d/%Y') if date_from.present?

    user = org_account.user

    account_list = profile.account_list

    begin
      response = Retryable.retryable on: Errors::UrlChanged, times: 1, then: update_url(:addresses_url) do
        get_response(
          org.addresses_url,
          get_params(
            org.addresses_params,
            profile: profile.code.to_s,
            datefrom: (date_from || org.minimum_gift_date).to_s,
            personid: org_account.remote_id
          )
        )
      end
    rescue DataServerError => e
      if e.message.include?('no profile associated')
        profile.destroy
        return
      end
      raise
    end

    import_donors_from_csv(account_list, profile, response, user)
    true
  end

  def import_donors_from_csv(account_list, profile, csv, user)
    CSV.new(csv, headers: :first_row, header_converters: ->(h) { h.upcase }).each do |line|
      next unless line['PEOPLE_ID']

      line['LAST_NAME'] = line['LAST_NAME_ORG']
      line['FIRST_NAME'] = line['ACCT_NAME'] if line['FIRST_NAME'].blank?

      begin
        donor_account = add_or_update_donor_account(line, profile, account_list)

        # handle bad data
        unless %w(P O).include?(line['PERSON_TYPE'])
          report_invalid_import_person_type(line)

          # Go ahead and assume this is a person
          # This follows the same expectations of TntConnect
          #
          # Contact Troy Wolbrink, troy@tntware.com, for questions about TntConnect
          line['PERSON_TYPE'] = 'P'
        end

        case line['PERSON_TYPE']
        when 'P' # Person
          # Create or update people associated with this account
          primary_person, primary_contact_person = add_or_update_primary_contact(account_list, line, donor_account)

          # Now the secondary person (persumably spouse)
          if line['SP_FIRST_NAME'].present?
            spouse, contact_spouse = add_or_update_spouse(account_list, line, donor_account)
            # Wed the two peple
            primary_person.add_spouse(spouse)
            primary_contact_person.add_spouse(contact_spouse)
          end
        when 'O' # Company/Organization
          add_or_update_company(account_list, user, line, donor_account)
        end
      rescue ArgumentError => e
        raise line.inspect + "\n\n" + e.message.inspect
      end
    end
  end

  def import_donations(profile, date_from = nil, date_to = nil)
    check_credentials!

    # if no date_from was passed in, use min date from query_ini
    date_from = date_from.strftime('%m/%d/%Y') if date_from.present?
    date_from = org.minimum_gift_date || '1/1/2004' if date_from.blank?
    date_to = Time.now.strftime('%m/%d/%Y') if date_to.blank?

    response = Retryable.retryable on: Errors::UrlChanged, times: 1, then: update_url(:donations_url) do
      get_response(
        org.donations_url,
        get_params(
          org.donations_params,
          profile: profile.code.to_s,
          datefrom: date_from,
          dateto: date_to,
          personid: org_account.remote_id
        )
      )
    end

    imported_donations = import_donations_from_csv(profile, response)
    delete_removed_donations(parse_date(date_from), parse_date(date_to),
                             imported_donations)
  end

  def delete_removed_donations(date_from, date_to, imported_donations)
    imported_by_designation = group_by_designation(imported_donations)
    imported_by_designation.keys.each do |designation_account|
      designation_account.donations.between(date_from, date_to)
                         .where.not(remote_id: imported_by_designation[designation_account].map(&:remote_id))
                         .where.not(remote_id: nil).find_each(&:destroy)
    end
  end

  def group_by_designation(imported_donations)
    by_designation = {}
    imported_donations.each do |donation|
      by_designation[donation.designation_account] ||= []
      by_designation[donation.designation_account] << donation
    end
    by_designation
  end

  def import_donations_from_csv(profile, response)
    CSV.new(response, headers: :first_row, header_converters: ->(h) { h.upcase }).read.map do |line|
      designation_account = find_or_create_designation_account(line['DESIGNATION'], profile)
      add_or_update_donation(line, designation_account, profile)
    end
  end

  def import_profile_balance(profile)
    check_credentials!

    balance = profile_balance(profile.code)
    attributes = { balance: balance[:balance], balance_updated_at: balance[:date] }
    profile.update_attributes(attributes)

    return unless balance[:designation_numbers] && balance[:designation_numbers].length == 1
    attributes[:name] = balance[:account_names].first
    balance[:designation_numbers].each_with_index do |number, _i|
      find_or_create_designation_account(number, profile, attributes)
    end
  end

  def check_credentials!
    return unless requires_credentials?
    raise_missing_credentials unless org_account.username && org_account.password || org_account.token
    unless org_account.valid_credentials?
      raise Person::OrganizationAccount::InvalidCredentialsError,
            format(_('Your credentials for %{org} are invalid.'), org: org)
    end
  end

  def validate_credentials
    begin
      if org.profiles_url.present?
        Retryable.retryable on: Errors::UrlChanged, times: 1, then: update_url(:profiles_url) do
          get_response(org.profiles_url, get_params(org.profiles_params))
        end
      else
        Retryable.retryable on: Errors::UrlChanged, times: 1, then: update_url(:account_balances_url) do
          get_response(org.account_balance_url, get_params(org.account_balance_params))
        end
      end
    rescue DataServerError => e
      # provid?ed is necessary because there is a typo in the error message
      return false if e.message =~ /password/ || e.message =~ /No client_id was provid?ed/
      raise e
    rescue Errno::ETIMEDOUT
      return false
    end
    true
  end

  def profiles_with_designation_numbers
    @profiles_with_designation_numbers ||= profiles.map do |profile|
      { designation_numbers: designation_numbers(profile[:code]) }
        .merge(profile.slice(:name, :code, :balance, :balance_udated_at))
    end
  end

  protected

  def profile_balance(profile_code)
    return {} unless org.account_balance_url
    balance = {}
    response = Retryable.retryable on: Errors::UrlChanged, times: 1, then: update_url(:account_balance_url) do
      get_response(org.account_balance_url,
                   get_params(org.account_balance_params, profile: profile_code.to_s))
    end

    # This csv should always only have one line (besides the headers)
    begin
      CSV.new(response, headers: :first_row).each do |line|
        balance[:designation_numbers] = line['EMPLID'].split(',').map { |e| e.delete('"') } if line['EMPLID']
        balance[:account_names] = line['ACCT_NAME'].split('\n') if line['ACCT_NAME']
        balance_match = line['BALANCE'].delete(',').match(/([-]?\d+\.?\d*)/)
        balance[:balance] = balance_match[0] if balance_match
        balance[:date] = line['EFFDT'] ? DateTime.strptime(line['EFFDT'], '%Y-%m-%d %H:%M:%S') : Time.now

        break
      end
    end
    balance
  end

  def designation_numbers(profile_code)
    balance = profile_balance(profile_code)
    balance[:designation_numbers]
  end

  def profiles
    unless @profiles
      @profiles = []
      unless org.profiles_url.blank?
        response = Retryable.retryable on: Errors::UrlChanged, times: 1, then: update_url(:profiles_url) do
          get_response(org.profiles_url, get_params(org.profiles_params))
        end

        begin
          CSV.new(response, headers: :first_row).each do |line|
            name = line['PROFILE_DESCRIPTION'] || line['ROLE_DESCRIPTION']
            code = line['PROFILE_CODE'] || line['ROLE_CODE']
            @profiles << { name: name, code: code }
          end
        rescue CSV::MalformedCSVError
          raise "CSV::MalformedCSVError: #{response}"
        end
      end
    end
    @profiles
  end

  def get_params(raw_params, options = {})
    params = Hash[raw_params.split('&').map { |p| p.split('=') }]
    replaced_params = {}
    params.each do |k, v|
      if v == '$ACCOUNT$'
        replaced_params[k] = org_account.token.blank? ? org_account.username : ''
      end
      if v == '$PASSWORD$'
        replaced_params[k] = org_account.token.blank? ? org_account.password : ''
      end
      replaced_params[k] = options[:profile] if options[:profile] && v == '$PROFILE$'
      replaced_params[k] = options[:datefrom] if options[:datefrom] && v == '$DATEFROM$'
      replaced_params[k] = options[:dateto] if options[:dateto].present? && v == '$DATETO$'
      replaced_params[k] = options[:personid].to_s if options[:personid].present? && v == '$PERSONIDS$'
    end
    unless org_account.token.blank?
      params['client_id'] = ENV.fetch('DONORHUB_CLIENT_ID')
      params['client_secret'] = ENV.fetch('DONORHUB_CLIENT_SECRET')
      params['client_instance'] = 'app'
      params['oauth_token'] = org_account.token
    end
    replaced_params.merge!(params.slice(*(params.keys - replaced_params.keys)))
    replaced_params
  end

  def get_response(url, params)
    request_params = {
      method: :post,
      url: url,
      payload: params,
      timeout: nil,
      user: u(org_account.username),
      password: u(org_account.password)
    }

    Rails.logger.debug(request_params)
    RestClient::Request.execute(request_params) do |response, _request, _result, &_block|
      raise_if_error_code(response)
      handle_ok_response(response)
    end
  rescue OpenSSL::SSL::SSLError => e
    raise DataServerError,
          format('Could not securely connect to host %p. Reason: %s',
                 URI(url).host, e)
  end

  def raise_if_error_code(response)
    code = response.code
    case code
    when 403 then
      raise_invalid_credentials
    when 404 then
      raise_missing_credentials
    when 500 then
      raise DataServerError, response
    end
  end

  def handle_ok_response(response)
    response = EncodingUtil.normalized_utf8(response.to_str)

    # check for error response
    lines = response.split(/\r?\n|\r/)
    first_line = lines.first.to_s.upcase
    first_two_lines = first_line + lines[1].to_s

    # provid?ed is necessary because there is a typo in the error message
    invalid_creds_errors = ['password', 'not registered', 'not authorized',
                            'oauth_token is not recognized', 'oauth_token is expired',
                            'No client_id was provid?ed']
    invalid_creds_regex = Regexp.new invalid_creds_errors.join('|'), true
    if first_two_lines =~ invalid_creds_regex
      raise_invalid_credentials
    elsif first_two_lines =~ /not found/i
      raise_missing_credentials
    elsif first_two_lines =~ /Timeout expired/i
      # if we encounter a network timeout, retry but don't alert rollbar
      raise LowerRetryWorker::RetryJobButNoRollbarError
    elsif first_line.include?('ERROR') || first_line.include?('HTML')
      raise DataServerError, response
    end

    # look for a redirect
    raise Errors::UrlChanged, lines[1].split('=')[1] if lines[1]&.include?('RedirectQueryIni')

    response
  end

  def raise_invalid_credentials
    org_account.update_column(:valid_credentials, false) if org_account.valid_credentials? && !org_account.new_record?

    raise Person::OrganizationAccount::InvalidCredentialsError,
          format(_('Your credentials for %{org} are invalid.'), org: org)
  end

  def raise_missing_credentials
    raise Person::OrganizationAccount::MissingCredentialsError,
          _('Your credentials are missing for this account.')
  end

  def add_or_update_primary_contact(account_list, line, donor_account)
    remote_id = "#{donor_account.account_number}-1"
    add_or_update_person(account_list, line, donor_account, remote_id, '')
  end

  def add_or_update_spouse(account_list, line, donor_account)
    remote_id = "#{donor_account.account_number}-2"
    add_or_update_person(account_list, line, donor_account, remote_id, 'SP_')
  end

  def add_or_update_person(account_list, line, donor_account, remote_id, prefix = '')
    org = donor_account.organization
    master_person_from_source = org.master_people.find_by('master_person_sources.remote_id' => remote_id.to_s)

    contact = donor_account.link_to_contact_for(account_list)
    if master_person_from_source
      person = donor_account.people
                            .joins(:contacts)
                            .where(master_person_id: master_person_from_source.id)
                            .where('contacts.account_list_id' => account_list.id)
                            .readonly(false)
                            .first
    end
    person ||= contact.people.find_by(first_name: line[prefix + 'FIRST_NAME'], last_name: line[prefix + 'LAST_NAME'])
    person ||= donor_account.people.find_by(master_person_id: master_person_from_source.id) if master_person_from_source

    person ||= Person.new(master_person: master_person_from_source)
    person.attributes = { first_name: line[prefix + 'FIRST_NAME'],
                          last_name: line[prefix + 'LAST_NAME'],
                          middle_name: line[prefix + 'MIDDLE_NAME'],
                          title: line[prefix + 'TITLE'],
                          suffix: line[prefix + 'SUFFIX'],
                          gender: prefix.present? ? 'female' : 'male' }
    # Make sure spouse always has a last name
    person.last_name = line['LAST_NAME'] if person.last_name.blank?

    # Phone numbers
    if line[prefix + 'PHONE'].present? && line[prefix + 'PHONE'] != line[prefix + 'MOBILE_PHONE']
      person.phone_number = { 'number' => line[prefix + 'PHONE'] }
    end
    if line[prefix + 'MOBILE_PHONE'].present?
      person.phone_number = { 'number' => line[prefix + 'MOBILE_PHONE'], 'location' => 'mobile' }
    end

    # email address
    if line[prefix + 'EMAIL'] && line[prefix + 'EMAIL_VALID'] != 'FALSE'
      email = line[prefix + 'EMAIL'].downcase
      unless person.email_addresses.exists?(email: email)
        person.email_address = { email: email, primary: true, source: 'DataServer' }
      end
    end

    person.master_person_id ||= MasterPerson.find_or_create_for_person(person, donor_account: donor_account).try(:id)
    person.save(validate: false)

    donor_account.people << person unless donor_account.people.include?(person)
    unless donor_account.master_people.include?(person.master_person)
      donor_account.master_people << person.master_person
    end

    contact = account_list.contacts.for_donor_account(donor_account).first
    contact_person = contact.add_person(person, donor_account)

    # create the master_person_source if needed
    unless master_person_from_source
      Retryable.retryable do
        org.master_person_sources
           .where(remote_id: remote_id.to_s)
           .first_or_create(master_person_id: person.master_person.id)
      end
    end

    [person, contact_person]
  end

  def add_or_update_company(account_list, user, line, donor_account)
    master_company = MasterCompany.find_by(name: line['LAST_NAME_ORG'])
    company = user.partner_companies.find_by(master_company_id: master_company.id) if master_company

    company ||= account_list.companies.new(master_company: master_company)
    company.assign_attributes(
      name: line['LAST_NAME_ORG'],
      phone_number: line['PHONE'],
      street: [line['ADDR1'], line['ADDR2'], line['ADDR3'], line['ADDR4']].select(&:present?).join("\n"),
      city: line['CITY'],
      state: line['STATE'],
      postal_code: line['ZIP'],
      country: line['CNTRY_DESCR']
    )
    company.save!
    unless donor_account.master_company_id == company.master_company.id
      donor_account.update_attributes(master_company_id: company.master_company_id)
    end
    company
  end

  def add_or_update_donor_account(line, profile, account_list = nil)
    account_list ||= profile.account_list
    donor_account = Retryable.retryable do
      donor_account = org.donor_accounts.where(account_number: line['PEOPLE_ID']).first_or_initialize
      # if the acccount already existed, update the name
      donor_account.attributes = { name: line['ACCT_NAME'],
                                   donor_type: line['PERSON_TYPE'] == 'P' ? 'Household' : 'Organization' }
      # physical address
      address_fields = [
        line['ADDR1'], line['ADDR2'], line['ADDR3'], line['ADDR4'], line['CITY'], line['STATE'], line['ZIP'],
        line['CNTRY_DESCR']
      ]
      if address_fields.any?(&:present?)
        donor_account.addresses_attributes = [{
          street: [line['ADDR1'], line['ADDR2'], line['ADDR3'], line['ADDR4']].select(&:present?).join("\n"),
          city: line['CITY'],
          state: line['STATE'],
          postal_code: line['ZIP'],
          country: line['CNTRY_DESCR'],
          source: 'DataServer',
          start_date: parse_date(line['ADDR_CHANGED']),
          primary_mailing_address: donor_account.addresses.find_by(primary_mailing_address: true).blank?
        }]
      end
      donor_account.save!
      donor_account
    end
    contact = donor_account.link_to_contact_for(account_list)
    raise 'Failed to link to contact' unless contact

    DataServer::ContactAddressUpdate.new(contact, donor_account).update_from_donor_account

    donor_account
  end

  def find_or_create_designation_account(number, profile, extra_attributes = {})
    @designation_accounts ||= {}
    unless @designation_accounts.key?(number)
      da = Retryable.retryable do
        org.designation_accounts.where(designation_number: number).first_or_create
      end
      profile.designation_accounts << da unless profile.designation_accounts.include?(da)
      da.update_attributes(extra_attributes) if extra_attributes.present?
      @designation_accounts[number] = da
    end
    @designation_accounts[number]
  end

  def add_or_update_donation(line, designation_account, profile)
    default_currency = org.default_currency_code || 'USD'
    donor_account = add_or_update_donor_account(line, profile)

    Retryable.retryable do
      date = line['DISPLAY_DATE'] ? Date.strptime(line['DISPLAY_DATE'], '%m/%d/%Y') : nil

      attributes = {
        amount: line['AMOUNT'],
        currency: default_currency,
        designation_account_id: designation_account.id,
        donation_date: date,
        donor_account_id: donor_account.id,
        memo: line['MEMO'],
        motivation: line['MOTIVATION'],
        payment_method: line['PAYMENT_METHOD'],
        remote_id: line['DONATION_ID'],
        tendered_amount: line['TENDERED_AMOUNT'].presence || line['AMOUNT'],
        tendered_currency: line['TENDERED_CURRENCY'].presence || default_currency
      }

      donation =
        DonationImports::Base::FindDonation.new(
          designation_profile: profile,
          attributes: attributes
        ).find_and_merge
      donation ||= Donation.new
      donation.update!(attributes)
      donation
    end
  end

  def update_url(url)
    proc do |exception, _handler, _attempts, _retries, _times|
      org.update_attributes(url => exception.message)
    end
  end

  # Data server supports two date formats, try both of those
  def parse_date(date_obj)
    return if date_obj.blank?
    return date_obj if date_obj.is_a?(Date)
    return date_obj.to_date if date_obj.is_a?(Time)
    Date.strptime(date_obj, '%m/%d/%Y')
  rescue ArgumentError
    begin
      Date.strptime(date_obj, '%Y-%m-%d')
    rescue ArgumentError
    end
  end

  def report_invalid_import_person_type(line)
    person_type = line['PERSON_TYPE']

    Rollbar.error(
      "Unknown PERSON_TYPE: #{line['PERSON_TYPE']}",
      parameters: {
        line: line,
        org: org.inspect,
        user: org_account.person.inspect,
        org_account: org_account.inspect
      }
    ) unless KNOWN_DIFFERING_IMPORT_PERSON_TYPES.include?(person_type) || person_type.to_s.empty?
  end
end

class DataServerError < StandardError
end
