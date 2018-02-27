require 'rails_helper'

RSpec.describe Audited::AuditSearch, type: :model do
  let(:audited) { create(:person, first_name: 'Stephan') }
  let(:user) { create(:user) }
  let(:audit_attributes) do
    {
      action: 'update',
      audited_changes: { first_name: %w(Steve Stephan) }.to_json,
      user_id: user.id,
      user_type: 'User',
      auditable_id: audited.id,
      auditable_type: audited.class.to_s
    }
  end
  let(:audit) { Audited::AuditElastic.new(audit_attributes) }

  let(:resp_body) do
    {
      "took": 1,
      "hits": {
        "total": 1,
        "max_score": 1,
        "hits": [
          {
            "_index": 'mpdx-test-2018.02.20',
            "_type": 'audit_elastic',
            "_id": '-Dals2EBy3eIl0ogkDQ5',
            "_score": 1,
            "_source": audit_attributes
          }
        ]
      }
    }
  end

  before do
    stub_request(:get, 'http://example.com:9200/mpdx-test-*/_search?scroll=5m&size=100&sort=_doc')
      .with(body: '{"query":{"bool":{"must":[{"match":{"auditable_type":"Person"}}]}},"sort":["_doc"]}')
      .to_return(status: 200, body: resp_body.to_json, headers: { 'content-type': 'application/json; charset=UTF-8' })
  end

  describe '#dump' do
    it 'loads all of class' do
      resp = described_class.dump('Person')

      expect(resp.first.auditable_id).to eq audited.id
    end
  end

  describe '#search_by' do
    it 'loads by params' do
      resp = described_class.search_by(bool: {
                                         must: [
                                           { match: { auditable_type: 'Person' } }
                                         ]
                                       })

      expect(resp.first.auditable_id).to eq audited.id
    end

    it 'loads by simple params' do
      resp = described_class.search_by(auditable_type: 'Person')

      expect(resp.first.auditable_id).to eq audited.id
    end
  end
end
