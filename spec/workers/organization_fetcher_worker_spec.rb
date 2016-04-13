require 'spec_helper'

describe OrganizationFetcherWorker do
  it 'fetches organizations' do
    tnt_stub = stub_request(:get, 'https://download.tntware.com/tntconnect/TntConnect_Organizations.csv')
               .to_return(body: "Name,QueryIni\nCru,http://cru.example.com")
    org_stub = stub_request(:get, 'http://cru.example.com')
    expect do
      OrganizationFetcherWorker.new.perform
    end.to change(Organization, :count).by(1)
    expect(tnt_stub).to have_been_requested
    expect(org_stub).to have_been_requested
  end

  describe 'guess_country' do
    subject { OrganizationFetcherWorker.new }
    it 'returns nil if no match found' do
      expect(subject.guess_country('No match here')).to be_nil
    end

    it 'finds a country after Parent org name' do
      expect(subject.guess_country('Cru - Panama')).to eq 'Panama'
    end

    it 'expands abbreviations' do
      expect(subject.guess_country('CAN')).to eq 'Canada'
      expect(subject.guess_country('Gospel For Asia   USA')).to eq 'United States'
    end
  end
end
