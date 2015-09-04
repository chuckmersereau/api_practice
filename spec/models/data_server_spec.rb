require 'spec_helper'

describe DataServer do
  let(:account_list) { create(:account_list) }
  let(:profile) { create(:designation_profile, organization: @org, user: @person.to_user, account_list: account_list) }

  let(:raw_data1) do
    "\"PEOPLE_ID\",\"ACCT_NAME\",\"ADDR1\",\"CITY\",\"STATE\",\"ZIP\",\"PHONE\",\"COUNTRY\",\"FIRST_NAME\",\"MIDDLE_NAME\",\"TITLE\",\"SUFFIX\","\
    "\"SP_LAST_NAME\",\"SP_FIRST_NAME\",\"SP_MIDDLE_NAME\",\"SP_TITLE\",\"ADDR2\",\"ADDR3\",\"ADDR4\",\"ADDR_CHANGED\",\"PHONE_CHANGED\",\"CNTRY_DESCR\","\
    "\"PERSON_TYPE\",\"LAST_NAME_ORG\",\"SP_SUFFIX\"\r\n\"17083\",\"Rodriguez, Ramon y Celeste (Moreno)\",\"Bahia Acapulco 379\",\"Chihuahua\",\"CHH\","\
    "\"24555\",\"(376) 706-670\",\"MEX\",\"Ramon\",\"\",\"Sr.\",\"\",\"Moreno\",\"Celeste\",\"Gonzalez\",\"Sra.\",\"\",\"\",\"\",\"4/4/2003\",\"4/4/2003\","\
    "\"\",\"P\",\"Rodriguez\",\"\"\r\n"
  end

  before(:each) do
    @org = create(:organization)
    @person = create(:person)
    @org_account = build(:organization_account, person: @person, organization: @org)
    @data_server = DataServer.new(@org_account)
  end

  it 'should import all' do
    date_from = '01/01/1951'
    expect(@data_server).to receive(:import_profiles).and_return([profile])
    expect(@data_server).to receive(:import_donors).with(profile, date_from)
    expect(@data_server).to receive(:import_donations).with(profile, date_from)
    @data_server.import_all(date_from)
  end

  it 'should return designation numbers for a profile code' do
    designation_numbers = ['031231']
    expect(@data_server).to receive(:profile_balance).and_return(designation_numbers: designation_numbers)
    expect(@data_server.send(:designation_numbers, profile.code)).to eq(designation_numbers)
  end

  it 'should return a list of all profiles with their associated designation numbers' do
    designation_numbers = ['031231']
    profiles = [{ name: 'Profile 1', code: 'Profile 1' }, { name: 'Profile 2', code: '' }]
    allow(@data_server).to receive(:designation_numbers).and_return(designation_numbers)
    allow(@data_server).to receive(:profiles).and_return(profiles)
    expect(@data_server.profiles_with_designation_numbers.first[:name]).to eq 'Profile 1'
    expect(@data_server.profiles_with_designation_numbers.first[:designation_numbers])
      .to eq(designation_numbers)
  end

  context '.import_profiles' do
    let(:data_server) { DataServer.new(@org_account) }

    it 'in US format' do
      stub_request(:post, /.*profiles/).to_return(body: "ROLE_CODE,ROLE_DESCRIPTION\n,\"Staff Account (0559826)\"\n")
      stub_request(:post, /.*accounts/).to_return(body: "\"EMPLID\",\"EFFDT\",\"BALANCE\",\"ACCT_NAME\"\n\"0000000\",\"2012-03-23 16:01:39.0\",\"123.45\",\"Test Account\"\n")
      expect(data_server).to receive(:import_profile_balance)

      expect do
        data_server.import_profiles
      end.to change(DesignationProfile, :count).by(1)
    end
    it 'in DataServer format' do
      stub_request(:post, /.*profiles/).to_return(body: "\xEF\xBB\xBF\"PROFILE_CODE\",\"PROFILE_DESCRIPTION\"\r\n\"1769360689\",\"MPD Coach (All Staff Donations)\"\r\n"\
                                                        "\"1769360688\",\"My Campus Accounts\"\r\n\"\",\"My Staff Account\"\r\n")
      stub_request(:post, /.*accounts/).to_return(body: "\"EMPLID\",\"EFFDT\",\"BALANCE\",\"ACCT_NAME\"\n\"0000000\",\"2012-03-23 16:01:39.0\",\"123.45\",\"Test Account\"\n")
      expect do
        data_server.import_profiles
      end.to change(DesignationProfile, :count).by(3)
    end
  end

  describe 'import donors' do
    it 'should update the addresses_url on the org if the url changed' do
      stub_request(:post, /.*addresses/).to_return(body: "whatever\nRedirectQueryIni=foo")
      stub_request(:post, 'http://foo:bar@foo/')
      expect do
        @data_server.import_donors(profile)
      end.to change(@org, :addresses_url).to('foo')
    end

    it 'removes a profile that a user no longer has access to' do
      stub_request(:post, /.*addresses/).to_return(body: 'ERROR The user logging in has no profile associated with "1983834942".')
      profile # instantiate record
      expect do
        @data_server.import_donors(profile)
      end.to change(DesignationProfile, :count).by(-1)
    end

    it 'should import a company' do
      stub_request(:post, /.*addresses/).to_return(body:
                                                     "\"PEOPLE_ID\",\"ACCT_NAME\",\"ADDR1\",\"CITY\",\"STATE\",\"ZIP\",\"PHONE\",\"COUNTRY\",\"FIRST_NAME\",\"MIDDLE_NAME\",\"TITLE\",\"SUFFIX\","\
        "\"SP_LAST_NAME\",\"SP_FIRST_NAME\",\"SP_MIDDLE_NAME\",\"SP_TITLE\",\"ADDR2\",\"ADDR3\",\"ADDR4\",\"ADDR_CHANGED\",\"PHONE_CHANGED\",\"CNTRY_DESCR\","\
        "\"PERSON_TYPE\",\"LAST_NAME_ORG\",\"SP_SUFFIX\"\r\n\"19238\",\"ACorporation\",\"123 mi casa blvd.\",\"Colima\",\"COL\",\"456788\",\"(52) 45 456-5678\","\
        "\"MEX\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"8/15/2003\",\"8/15/2003\",\"\",\"O\",\"ACorporation\",\"\"\r\n")
      expect(@data_server).to receive(:add_or_update_donor_account)
      expect(@data_server).to receive(:add_or_update_company)
      @data_server.import_donors(profile)
    end

    it 'should import an individual' do
      stub_request(:post, /.*addresses/).to_return(body: raw_data1)
      primary_contact = double('person')
      other_person = double('person')
      expect(@data_server).to receive(:add_or_update_primary_contact)
        .and_return([primary_contact, other_person])
      expect(@data_server).to receive(:add_or_update_spouse)
      expect(primary_contact).to receive(:add_spouse)
      expect(other_person).to receive(:add_spouse)
      @data_server.import_donors(profile)
    end

    it 'should create a new contact in the right account list' do
      stub_request(:post, /.*addresses/).to_return(body: raw_data1)
      @account_list1 = create(:account_list)
      @account_list2 = create(:account_list)
      profile = create(:designation_profile, user: @org_account.user, account_list: @account_list2)
      @org_account.user.account_lists = [@account_list1, @account_list2]
      expect do
        @data_server.import_donors(profile)
      end.to change(Contact, :count)
      expect(@account_list2.contacts.last.name).to eq('Rodriguez, Ramon y Celeste (Moreno)')
    end

    it 'should create a new person in the right account list and donor account' do
      stub_request(:post, /.*addresses/).to_return(body: raw_data1)
      @account_list1 = create(:account_list)
      @account_list2 = create(:account_list)
      profile = create(:designation_profile, user: @org_account.user, account_list: @account_list2)
      @org_account.user.account_lists = [@account_list1, @account_list2]
      donor_account = create(:donor_account, organization: @org_account.organization, account_number: '17083')
      expect do
        @data_server.import_donors(profile)
      end.to change(Person, :count)
      new_person = @account_list2.contacts.last.people.order('contact_people.primary::int desc').references(:contact_people).last
      expect(new_person.last_name).to eq 'Rodriguez'
      expect(new_person.middle_name).to eq ''
      expect(new_person.donor_accounts.last).to eq donor_account

      stub_request(:post, /.*addresses/).to_return(body:
                                                     "\"PEOPLE_ID\",\"ACCT_NAME\",\"ADDR1\",\"CITY\",\"STATE\",\"ZIP\",\"PHONE\",\"COUNTRY\",\"FIRST_NAME\",\"MIDDLE_NAME\",\"TITLE\",\"SUFFIX\","\
        "\"SP_LAST_NAME\",\"SP_FIRST_NAME\",\"SP_MIDDLE_NAME\",\"SP_TITLE\",\"ADDR2\",\"ADDR3\",\"ADDR4\",\"ADDR_CHANGED\",\"PHONE_CHANGED\",\"CNTRY_DESCR\","\
        "\"PERSON_TYPE\",\"LAST_NAME_ORG\",\"SP_SUFFIX\"\r\n\"17083\",\"Rodrigues, Ramon y Celeste (Moreno)\",\"Bahia Acapulco 379\",\"Chihuahua\",\"CHH\","\
        "\"24555\",\"(376) 706-670\",\"MEX\",\"Ramon\",\"C\",\"Sr.\",\"\",\"Moreno\",\"Celeste\",\"Gonzalez\",\"Sra.\",\"\",\"\",\"\",\"4/4/2003\",\"4/4/2003\","\
        "\"\",\"P\",\"Rodrigues\",\"\"\r\n")
      @data_server.import_donors(profile)
      expect(new_person.reload.last_name).to eq 'Rodrigues'
      expect(new_person.middle_name).to eq 'C'
    end

    it "should notify Airbrake if PERSON_TYPE is not 'O' or 'P'" do
      stub_request(:post, /.*addresses/).to_return(body:
                                                     "\"PEOPLE_ID\",\"ACCT_NAME\",\"ADDR1\",\"CITY\",\"STATE\",\"ZIP\",\"PHONE\",\"COUNTRY\",\"FIRST_NAME\",\"MIDDLE_NAME\",\"TITLE\",\"SUFFIX\","\
        "\"SP_LAST_NAME\",\"SP_FIRST_NAME\",\"SP_MIDDLE_NAME\",\"SP_TITLE\",\"ADDR2\",\"ADDR3\",\"ADDR4\",\"ADDR_CHANGED\",\"PHONE_CHANGED\",\"CNTRY_DESCR\","\
        "\"PERSON_TYPE\",\"LAST_NAME_ORG\",\"SP_SUFFIX\"\r\n\"17083\",\"Rodriguez, Ramon y Celeste (Moreno)\",\"Bahia Acapulco 379\",\"Chihuahua\",\"CHH\","\
        "\"24555\",\"(376) 706-670\",\"MEX\",\"Ramon\",\"\",\"Sr.\",\"\",\"Moreno\",\"Celeste\",\"Gonzalez\",\"Sra.\",\"\",\"\",\"\",\"4/4/2003\",\"4/4/2003\","\
        "\"\",\"BAD_PERSON_TYPE\",\"Rodriguez\",\"\"\r\n")
      expect(Airbrake).to receive(:notify)
      @data_server.import_donors(profile)
    end
    it 'should add or update primary contact' do
      expect(@data_server).to receive(:add_or_update_person)
      @data_server.send(:add_or_update_primary_contact, create(:account_list), '', create(:donor_account))
    end
    it 'should add or update spouse' do
      expect(@data_server).to receive(:add_or_update_person)
      @data_server.send(:add_or_update_spouse, create(:account_list), '', create(:donor_account))
    end

    describe 'add or update a company' do
      let(:line) do
        { 'PEOPLE_ID' => '19238', 'ACCT_NAME' => 'ACorporation', 'ADDR1' => '123 mi casa blvd.', 'CITY' => 'Colima', 'STATE' => 'COL',
          'ZIP' => '456788', 'PHONE' => '(52) 45 456-5678', 'COUNTRY' => 'MEX', 'FIRST_NAME' => '', 'MIDDLE_NAME' => '', 'TITLE' => '',
          'SUFFIX' => '', 'SP_LAST_NAME' => '', 'SP_FIRST_NAME' => '', 'SP_MIDDLE_NAME' => '', 'SP_TITLE' => '', 'ADDR2' => '', 'ADDR3' => '',
          'ADDR4' => '', 'ADDR_CHANGED' => '8/15/2003', 'PHONE_CHANGED' => '8/15/2003', 'CNTRY_DESCR' => '', 'PERSON_TYPE' => 'O',
          'LAST_NAME_ORG' => 'ACorporation', 'SP_SUFFIX' => '' }
      end

      before(:each) do
        @account_list = create(:account_list)
        @user = User.find(@person.id)
        @donor_account = create(:donor_account)
      end
      it 'should add a company with an existing master company' do
        create(:company, name: 'ACorporation')
        expect do
          @data_server.send(:add_or_update_company, @account_list, @user, line, @donor_account)
        end.to_not change(MasterCompany, :count)
      end
      it 'should add a company without an existing master company and create a master company' do
        expect do
          @data_server.send(:add_or_update_company, @account_list, @user, line, @donor_account)
        end.to change(MasterCompany, :count).by(1)
      end
      it 'should update an existing company' do
        company = create(:company, name: 'ACorporation')
        @user.account_lists << @account_list
        @account_list.companies << company
        expect do
          new_company = @data_server.send(:add_or_update_company, @account_list, @user, line, @donor_account)
          expect(new_company).to eq(company)
        end.to_not change(Company, :count)
      end
      it 'should associate new company with the donor account' do
        @data_server.send(:add_or_update_company, @account_list, @user, line, @donor_account)
        expect(@donor_account.master_company_id).not_to be_nil
      end
    end

    describe 'add or update contact' do
      let(:line) do
        { 'PEOPLE_ID' => '17083', 'ACCT_NAME' => 'Rodrigue', 'ADDR1' => 'Ramon y Celeste (Moreno)', 'CITY' => 'Bahia Acapulco 379',
          'STATE' => 'Chihuahua', 'ZIP' => 'CHH', 'PHONE' => '24555', 'COUNTRY' => '(376) 706-670', 'FIRST_NAME' => 'MEX',
          'MIDDLE_NAME' => 'Ramon', 'TITLE' => '', 'SUFFIX' => 'Sr.', 'SP_LAST_NAME' => '', 'SP_FIRST_NAME' => 'Moreno',
          'SP_MIDDLE_NAME' => 'Celeste', 'SP_TITLE' => 'Gonzalez', 'ADDR2' => 'Sra.', 'ADDR3' => '', 'ADDR4' => '',
          'ADDR_CHANGED' => '', 'PHONE_CHANGED' => '4/4/2003', 'CNTRY_DESCR' => '4/4/2003', 'PERSON_TYPE' => '',
          'LAST_NAME_ORG' => 'P', 'SP_SUFFIX' => 'Rodriguez' }
      end

      before(:each) do
        @account_list = create(:account_list)
        @user = User.find(@person.id)
        @donor_account = create(:donor_account)
        @donor_account.link_to_contact_for(@account_list)
      end
      it 'should add a contact with an existing master person' do
        mp = create(:master_person)
        @donor_account.organization.master_person_sources.create(master_person_id: mp.id, remote_id: 1)
        expect do
          @data_server.send(:add_or_update_person, @account_list, line, @donor_account, 1)
        end.to_not change(MasterPerson, :count)
      end
      it 'should add a contact without an existing master person and create a master person' do
        expect do
          expect do
            @data_server.send(:add_or_update_person, @account_list, line, @donor_account, 1)
          end.to change(MasterPerson, :count).by(1)
        end.to change(Person, :count).by(2)
      end

      it 'should add a new contact with no spouse prefix' do
        expect do
          @data_server.send(:add_or_update_person, @account_list, line, @donor_account, 1)
        end.to change(MasterPerson, :count).by(1)
      end
      it 'should add a new contact with a spouse prefix' do
        expect do
          @data_server.send(:add_or_update_person, @account_list, line, @donor_account, 1, 'SP_')
        end.to change(MasterPerson, :count).by(1)
      end
      it 'should update an existing person' do
        person = create(:person)
        @user.account_lists << @account_list
        @donor_account.master_people << person.master_person
        @donor_account.people << person
        @donor_account.organization.master_person_sources.create(master_person_id: person.master_person_id, remote_id: 1)
        expect do
          new_contact, _other = @data_server.send(:add_or_update_person, @account_list, line, @donor_account, 1)
          expect(new_contact).to eq(person)
        end.to_not change(MasterPerson, :count)
      end
      it 'should associate new contacts with the donor account' do
        expect do
          @data_server.send(:add_or_update_person, @account_list, line, @donor_account, 1)
        end.to change(MasterPersonDonorAccount, :count).by(1)
      end
    end
  end

  context '#add_or_update_donor_account' do
    before do
      stub_request(:get, %r{https://api\.smartystreets\.com/street-address/.*}).to_return(body: '[]')
    end

    let(:line) do
      { 'PEOPLE_ID' => '17083', 'ACCT_NAME' => 'Rodrigue', 'ADDR1' => 'Ramon y Celeste (Moreno)', 'CITY' => 'Bahia Acapulco 379',
        'STATE' => 'Chihuahua', 'ZIP' => '24555', 'PHONE' => '(376) 706-670', 'COUNTRY' => 'CHH', 'FIRST_NAME' => 'Ramon',
        'MIDDLE_NAME' => '', 'TITLE' => '', 'SUFFIX' => 'Sr.', 'SP_LAST_NAME' => '', 'SP_FIRST_NAME' => 'Moreno',
        'SP_MIDDLE_NAME' => 'Celeste', 'SP_TITLE' => 'Gonzalez', 'ADDR2' => 'Sra.', 'ADDR3' => '', 'ADDR4' => '',
        'ADDR_CHANGED' => '2/14/2002', 'PHONE_CHANGED' => '4/4/2003', 'CNTRY_DESCR' => 'USA', 'PERSON_TYPE' => '',
        'LAST_NAME_ORG' => 'P', 'SP_SUFFIX' => 'Rodriguez' }
    end

    it 'creates a new contact' do
      expect do
        @data_server.send(:add_or_update_donor_account, line, profile)
      end.to change(Contact, :count)
    end

    it "doesn't add duplicate addresses with standard country name, just one correct address" do
      line['CNTRY_DESCR'] = 'United States'
      expect do
        @data_server.send(:add_or_update_donor_account, line, profile)
      end.to change(Address, :count).by(2)
      expect do
        @data_server.send(:add_or_update_donor_account, line, profile)
      end.to change(Address, :count).by(0)

      expect(account_list.contacts.count).to eq(1)
      contact = account_list.contacts.first
      expect(contact.donor_accounts.count).to eq(1)
      donor_account = contact.donor_accounts.first

      expect(contact.addresses.count).to eq(1)
      contact_address = contact.addresses.first
      expect(donor_account.addresses.count).to eq(1)
      donor_address = donor_account.addresses.first

      expected_attrs = {
        street: "Ramon y Celeste (Moreno)\nSra.", city: 'Bahia Acapulco 379', country: 'United States',
        postal_code: '24555', source: 'DataServer', start_date: Date.new(2002, 2, 14)
      }
      expect(contact_address.attributes.symbolize_keys.slice(*expected_attrs.keys)).to eq(expected_attrs)
      expect(donor_address.attributes.symbolize_keys.slice(*expected_attrs.keys)).to eq(expected_attrs)
    end

    it "doesn't add duplicate addresses with alternate country name" do
      expect do
        @data_server.send(:add_or_update_donor_account, line, profile)
      end.to change(Address, :count).by(2)
      expect do
        @data_server.send(:add_or_update_donor_account, line, profile)
      end.to change(Address, :count).by(0)
    end

    it 'sets the address as primary if the donor account has no other primary addresses' do
      @data_server.send(:add_or_update_donor_account, line, profile)
      contact = account_list.contacts.first
      donor_account = contact.donor_accounts.first
      expect(contact.reload.addresses.where(primary_mailing_address: true).count).to eq(1)
      expect(donor_account.reload.addresses.where(primary_mailing_address: true).count).to eq(1)
    end

    it 'leaves existing primary address in the donor account' do
      donor_account = create(:donor_account, organization: @org, account_number: '17083')
      prior_address = create(:address, primary_mailing_address: true)
      donor_account.addresses << prior_address
      @data_server.send(:add_or_update_donor_account, line, profile)
      contact = account_list.contacts.first
      expect(contact.reload.addresses.where(primary_mailing_address: true).count).to eq(1)
      expect(donor_account.reload.addresses.where(primary_mailing_address: true).count).to eq(1)

      expect(prior_address.reload.primary_mailing_address).to be true
      expect(contact.addresses.find_by_street(prior_address.street).primary_mailing_address).to be true
    end
  end

  describe 'check_credentials!' do
    it 'raise an error if credentials are missing' do
      no_user_account = @org_account.dup
      no_user_account.username = nil
      expect do
        DataServer.new(no_user_account).import_donors(profile)
      end.to raise_error(OrgAccountMissingCredentialsError, 'Your username and password are missing for this account.')
      no_pass_account = @org_account.dup
      no_pass_account.password = nil
      expect do
        DataServer.new(no_pass_account).import_donors(profile)
      end.to raise_error(OrgAccountMissingCredentialsError, 'Your username and password are missing for this account.')
    end
    it 'raise an error if credentials are invalid' do
      @org_account.valid_credentials = false
      expect do
        DataServer.new(@org_account).import_donors(profile)
      end.to raise_error(OrgAccountInvalidCredentialsError,
                         _('Your username and password for %{org} are invalid.').localize % { org: @org })
    end
  end

  describe 'validate_username_and_password' do
    it 'should validate using the profiles url if there is one' do
      expect(@data_server).to receive(:get_params).and_return({})
      expect(@data_server).to receive(:get_response).with(@org.profiles_url, {})
      expect(@data_server.validate_username_and_password).to eq(true)
    end
    it 'should validate using the account balance url if there is no profiles url' do
      @org.profiles_url = nil
      expect(@data_server).to receive(:get_params).and_return({})
      expect(@data_server).to receive(:get_response).with(@org.account_balance_url, {})
      expect(@data_server.validate_username_and_password).to eq(true)
    end
    it 'should return false if the error message says the username/password were wrong' do
      expect(@data_server).to receive(:get_response).and_raise(DataServerError.new('Either your username or password were incorrect.'))
      expect(@data_server.validate_username_and_password).to eq(false)
    end
    it 'should re-raise other errors' do
      expect(@data_server).to receive(:get_response).and_raise(DataServerError.new('other error'))
      expect do
        @data_server.validate_username_and_password
      end.to raise_error(DataServerError)
    end
  end

  describe 'get_response' do
    it 'should raise a DataServerError if the first line of the response is ERROR' do
      stub_request(:post, 'http://foo:bar@example.com').to_return(body: "ERROR\nmessage")
      expect do
        @data_server.send(:get_response, 'http://example.com', {})
      end.to raise_error(DataServerError, "ERROR\nmessage")
    end

    def expect_bad_passsword_err(data_server_body)
      stub_request(:post, 'http://foo:bar@example.com').to_return(body: data_server_body)
      expect do
        @data_server.send(:get_response, 'http://example.com', {})
      end.to raise_error(OrgAccountInvalidCredentialsError, 'Your username and password for MyString are invalid.')
    end

    it 'raises OrgAccountInvalidCredentialsError if the first line of the response is BAD_PASSWORD' do
      expect_bad_passsword_err("BAD_PASSWORD\nmessage")
    end

    it 'raises OrgAccountInvalidCredentialsError if the first line includes the word "password"' do
      expect_bad_passsword_err("You have entered an invalid login and/or password\nmessage")
    end

    it 'raises OrgAccountInvalidCredentialsError if the second line includes the word "password"' do
      expect_bad_passsword_err("﻿ERROR\rAn error occurred in GetServiceTicketFromUserNamePassword")
    end

    it 'raises OrgAccountInvalidCredentialsError if the second line includes the word "password"' do
      expect_bad_passsword_err("﻿ERROR\nPerhaps the username or password are incorrect")
    end

    it 'raises OrgAccountInvalidCredentialsError if the second line includes the phrase "not registered"' do
      expect_bad_passsword_err("﻿ERROR\nThe user logging in is not registered with this system")
    end

    it 'raises OrgAccountInvalidCredentialsError if the first line includes a byte order mark' do
      expect_bad_passsword_err("ERROR\r\nAuthentication failed.  Perhaps the username or password are incorrect.")
    end

    it 'raises no error when the creds are encoded' do
      @org_account.username = 'tester@tester.com'
      @org_account.password = 'abcd543!'

      execute_params = {
        method: :post, url: 'http://example.com', payload: [], timeout: -1,
        user: 'tester%40tester.com', password: 'abcd543%21'
      }
      # We can't use webmock to spec this since webmock smart matches on encoding
      expect(RestClient::Request).to_not receive(:execute).with(execute_params)
      @data_server.send(:get_response, 'http://example.com', {})
    end

    it 'correctly parses special characters in utf-8' do
      stub_request(:post, 'http://foo:bar@example.com').to_return(body: 'Agapé')
      expect(@data_server.send(:get_response, 'http://example.com', {}))
        .to eq('Agapé')
    end
  end

  describe 'import account balances' do
    it 'should update a profile balance' do
      stub_request(:post, /.*accounts/).to_return(body: "\"EMPLID\",\"EFFDT\",\"BALANCE\",\"ACCT_NAME\"\n\"0000000\",\"2012-03-23 16:01:39.0\",\"123.45\",\"Test Account\"\n")
      expect(@data_server).to receive(:check_credentials!)
      expect do
        @data_server.import_profile_balance(profile)
      end.to change(profile, :balance).to(123.45)
    end
    it 'should update a designation account balance' do
      stub_request(:post, /.*accounts/).to_return(body: "\"EMPLID\",\"EFFDT\",\"BALANCE\",\"ACCT_NAME\"\n\"0000000\",\"2012-03-23 16:01:39.0\",\"123.45\",\"Test Account\"\n")
      @designation_account = create(:designation_account, organization: @org, designation_number: '0000000')
      @data_server.import_profile_balance(profile)
      expect(@designation_account.reload.balance).to eq(123.45)
    end
  end

  describe 'import donations' do
    let(:line) do
      { 'DONATION_ID' => '1062', 'PEOPLE_ID' => '12271', 'ACCT_NAME' => 'Garci, Reynaldo', 'DESIGNATION' => '10640', 'MOTIVATION' => '',
        'PAYMENT_METHOD' => 'EFECTIVO', 'TENDERED_CURRENCY' => 'MXN', 'MEMO' => '', 'DISPLAY_DATE' => '4/23/2003', 'AMOUNT' => '1000.0000',
        'TENDERED_AMOUNT' => '1000.0000' }
    end

    def stub_donations_request
      stub_request(:post, /.*donations/).to_return(body:
                                                     "\xEF\xBB\xBF\"DONATION_ID\",\"PEOPLE_ID\",\"ACCT_NAME\",\"DESIGNATION\",\"MOTIVATION\",\"PAYMENT_METHOD\",\"TENDERED_CURRENCY\",\"MEMO\","\
        "\"DISPLAY_DATE\",\"AMOUNT\",\"TENDERED_AMOUNT\"\r\n\"1062\",\"12271\",\"Garcia, Reynaldo\",\"10640\",\"\",\"EFECTIVO\",\"MXN\",\"\",\"4/23/2003\","\
        "\"1000.0000\",\"1000.0000\"\r\n")
      expect(@data_server).to receive(:check_credentials!)
    end

    it 'creates a donation' do
      stub_donations_request
      expect(@data_server).to receive(:find_or_create_designation_account)
      expect(@data_server).to receive(:add_or_update_donation)
      expect(@data_server).to receive(:delete_removed_donations)
      @data_server.import_donations(profile, DateTime.new(1951, 1, 1), '2/2/2012')
    end

    it 'removes non-manual donations in the date range but no longer in import', versioning: true do
      stub_donations_request
      da = create(:designation_account, organization: @org, designation_number: line['DESIGNATION'])

      removed_donation = create(:donation)
      manual_donation = create(:donation, remote_id: nil)
      old_donation = create(:donation, donation_date: 1.month.ago)
      da.donations += [manual_donation, old_donation, removed_donation]
      other_designation = create(:donation)

      expect do
        @data_server.import_donations(profile, Date.today - 2.weeks, Date.today)
      end.to change(Version.where(item_type: 'Donation'), :count).by(1)

      expect(Donation.find_by(id: removed_donation.id)).to be_nil
      expect(Donation.find(manual_donation.id)).to be_present
      expect(Donation.find(old_donation.id)).to be_present
      expect(Donation.find(other_designation.id)).to be_present
    end

    it 'finds an existing designation account' do
      account = create(:designation_account, organization: @org, designation_number: line['DESIGNATION'])
      expect(@data_server.send(:find_or_create_designation_account, line['DESIGNATION'], profile)).to eq(account)
    end

    it 'creates a new designation account' do
      expect do
        @data_server.send(:find_or_create_designation_account, line['DESIGNATION'], profile)
      end.to change(DesignationAccount, :count)
    end

    describe 'add or update donation' do
      let(:designation_account) { create(:designation_account) }

      it 'adds a new donation' do
        expect do
          @data_server.send(:add_or_update_donation, line, designation_account, profile)
        end.to change(Donation, :count)
      end
      it 'updates an existing donation' do
        @data_server.send(:add_or_update_donation, line, designation_account, profile)
        expect do
          donation = @data_server.send(:add_or_update_donation, line.merge!('AMOUNT' => '5'), designation_account, profile)
          expect(donation.amount).to eq(5)
        end.to_not change(Donation, :count)
      end
    end

    context '#parse_date' do
      it 'supports dates formatted as %m/%d/%y %H:%M:%S' do
        expect(@data_server.send(:parse_date, '5/15/2014 15:22:13')).to eq(Date.new(2014, 5, 15))
      end

      it 'supports dates formatted as MM/DD/YYYY' do
        expect(@data_server.send(:parse_date, '5/15/2014')).to eq(Date.new(2014, 5, 15))
      end

      it 'supports dates formatted as YYYY-MM-DD' do
        expect(@data_server.send(:parse_date, '2014-05-15')).to eq(Date.new(2014, 5, 15))
      end

      it 'returns nil for a badly formatted date' do
        expect(@data_server.send(:parse_date, '2014-99-2')).to be_nil
      end

      it 'returns nil for nil' do
        expect(@data_server.send(:parse_date, nil)).to be_nil
      end

      it 'returns nil for empty string' do
        expect(@data_server.send(:parse_date, '')).to be_nil
      end

      it 'returns the date if given a date object' do
        expect(@data_server.send(:parse_date, Date.today)).to eq Date.today
      end

      it 'returns the date for a time if given' do
        expect(@data_server.send(:parse_date, Time.now)).to eq Date.today
      end
    end
  end
end
