require 'rails_helper'

RSpec.describe OrganizationsFromCsvUrlWorker do
  let!(:csv_url) { 'https://download.tntware.com/donorhub/donorhub_api_organizations.csv' }
  let!(:request) do
    stub_request(:get, csv_url)
      .to_return(body:
        "Name,QueryIni\nAgape Iceland,http://dataserver1.com\nToonTown,\nTandem Ministries,http://dataserver2.com")
  end

  describe '#perform' do
    it 'creates OrganizationFromQueryUrlWorker jobs' do
      expect(OrganizationFromQueryUrlWorker).to(
        receive(:perform_async).with('Agape Iceland', 'http://dataserver1.com')
      )
      expect(OrganizationFromQueryUrlWorker).to(
        receive(:perform_async).with('Tandem Ministries', 'http://dataserver2.com')
      )
      described_class.new.perform(csv_url)
      expect(request).to have_been_requested
    end
  end
end
