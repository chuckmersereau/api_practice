require 'rails_helper'

describe RowTransferRequest do
  describe 'transfer' do
    let!(:mock) do
      stub_request(:post, 'http://example.com/')
    end
    let(:uuids) { %w(fc691be1-f667-46a5-bdbd-5b2751d98a90 d0be514b-d59f-4b57-9344-97317ab26c11) }
    let(:table_name) { 'people' }

    it 'sends those uuids to Kirby' do
      RowTransferRequest.transfer(table_name, uuids)

      expected_body = { table: table_name, uuids: uuids.join(','), clone: true, safe: true }
      expect(mock.with(body: expected_body)).to have_been_made.once
    end
  end
end