require 'spec_helper'

describe OrganizationFetcherWorker do
  it 'fetches organizations' do
    stub = stub_request(:get, 'http://download.tntware.com/tntmpd/TntMPD_Organizations.csv')
           .to_return(body: "Name,QueryIni\nCru,cru.example.com")
    expect do
      OrganizationFetcherWorker.new.perform
    end.to change(Organization, :count).by(1)
    expect(stub).to have_been_requested
  end
end
