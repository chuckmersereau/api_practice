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
end
