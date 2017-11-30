require 'rails_helper'

RSpec.describe OrganizationFromQueryUrlWorker do
  let(:name) { 'CCCNZ' }
  let(:query_ini_url) { 'https://tntdataserverasia.com/dataserver/nzl/dataquery/tntquery.aspx' }
  let(:organization) { Organization.first || create(:organization) }
  let(:ini_body) { File.open(Rails.root.join('spec', 'fixtures', 'sample_query.ini')).read }
  let(:ini) { IniParse.parse(ini_body) }

  before do
    stub_request(:get, query_ini_url)
      .to_return(
        body: ini_body
      )
  end

  it 'has the correct sections' do
    expect(described_class::SECTIONS.keys).to eq(
      %w(ACCOUNT_BALANCE DONATIONS ADDRESSES ADDRESSES_BY_PERSONIDS PROFILES
         OAuth_GetChallengeStartNum OAuth_ConvertToToken OAuth_GetTokenInfo)
    )
  end

  describe '#perform' do
    let(:perform) { described_class.new.perform(name, query_ini_url) }

    it 'creates an organization' do
      expect { perform }.to change { Organization.count }.from(0).to(1)
    end

    describe 'attributes' do
      before { perform }

      it 'sets the correct organization_attributes' do
        expect(organization.name).to eq name
        expect(organization.query_ini_url).to eq query_ini_url
        expect(organization.redirect_query_ini).to eq ini['ORGANIZATION']['RedirectQueryIni']
        expect(organization.abbreviation).to eq ini['ORGANIZATION']['Abbreviation']
        expect(organization.logo).to eq ini['ORGANIZATION']['WebLogo-JPEG-470x120']
        expect(organization.account_help_url).to eq ini['ORGANIZATION']['AccountHelpUrl']
        expect(organization.minimum_gift_date).to eq ini['ORGANIZATION']['MinimumWebGiftDate']
        expect(organization.code).to eq ini['ORGANIZATION']['Code']
        expect(organization.query_authentication).to eq ini['ORGANIZATION']['QueryAuthentication'].to_i == 1
        expect(organization.org_help_email).to eq ini['ORGANIZATION']['OrgHelpEmail']
        expect(organization.org_help_url).to eq ini['ORGANIZATION']['OrgHelpUrl']
        expect(organization.org_help_url_description).to eq ini['ORGANIZATION']['OrgHelpUrlDescription']
        expect(organization.org_help_other).to eq ini['ORGANIZATION']['OrgHelpOther']
        expect(organization.request_profile_url).to eq ini['ORGANIZATION']['RequestProfileUrl']
        expect(organization.staff_portal_url).to eq ini['ORGANIZATION']['StaffPortalUrl']
        expect(organization.default_currency_code).to eq ini['ORGANIZATION']['DefaultCurrencyCode']
        expect(organization.allow_passive_auth).to eq ini['ORGANIZATION']['AllowPassiveAuth'] == 'True'
        expect(organization.oauth_url).to eq ini['ORGANIZATION']['OAuthUrl']
      end

      described_class::SECTIONS.each do |key, section|
        it "sets the correct #{section}_attributes" do
          expect(organization.send("#{section}_url")).to eq ini[key]['Url']
          expect(organization.send("#{section}_params")).to eq ini[key]['Post'] unless key == 'DONATIONS'
          expect(organization.send("#{section}_oauth")).to eq ini[key]['OAuth']
        end
      end

      it 'sets the correct donation_params' do
        expect(organization.donations_params).to eq ini['DONATIONS.3.4']['Post']
      end
    end

    context 'organization name already exists' do
      before { create(:organization, name: name, query_ini_url: 'random', minimum_gift_date: Date.yesterday) }

      it 'does not create an organization' do
        expect { perform }.to_not change { Organization.count }
      end

      it 'updates query_ini_url' do
        perform
        expect(organization.query_ini_url).to eq query_ini_url
      end

      it 'does not change minimum_gift_date' do
        perform
        expect(organization.minimum_gift_date).to_not eq ini['ORGANIZATION']['MinimumWebGiftDate']
      end
    end

    context 'organization query_ini_url already exists' do
      before { create(:organization, query_ini_url: query_ini_url, name: 'random') }

      it 'does not create an organization' do
        expect { perform }.to_not change { Organization.count }
      end

      it 'updates name' do
        perform
        expect(organization.name).to eq name
      end
    end
  end
end
