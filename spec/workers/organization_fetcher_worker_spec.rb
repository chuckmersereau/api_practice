require 'spec_helper'

describe OrganizationFetcherWorker do
  it 'fetches organizations' do
    tnt_stub = stub_request(:get, 'https://download.tntware.com/tntconnect/TntConnect_Organizations.csv')
               .to_return(body: "Name,QueryIni\nAgape Iceland,http://example.com")
    org_stub = stub_request(:get, 'http://example.com')

    expect do
      OrganizationFetcherWorker.new.perform
    end.to change(Organization, :count).by(1)

    expect(tnt_stub).to have_been_requested
    expect(org_stub).to have_been_requested
    expect(Organization.last.locale).to eq 'is'
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

  context '#guess_locale' do
    it 'returns en if blank country given' do
      expect(subject.guess_locale('')).to eq 'en'
    end

    it 'returns en if a non-existent country given' do
      expect(subject.guess_locale('Not-A-Country')).to eq 'en'
    end

    it 'returns locale of a real country' do
      expect(subject.guess_locale('France')).to eq 'fr'
    end
  end
end
