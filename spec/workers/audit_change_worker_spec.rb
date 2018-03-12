require 'rails_helper'

describe AuditChangeWorker do
  let(:attrs) do
    {
      action: 'update',
      audited_changes: '{"legal_first_name"=>["Spenc", nil]}',
      comment: nil, 'created_at' => '2018-03-09T10:47:24-05:00',
      request_uuid: nil,
      remote_address: nil,
      user_id: 1,
      user_type: 'User',
      auditable_id: 1, 'auditable_type' => 'User',
      associated_id: 1, 'associated_type' => 'Contact'
    }
  end
  let(:mock_gateway) { double(:mock_gateway) }

  subject { described_class.new.perform(attrs) }

  before do
    allow(Audited::AuditElastic).to receive(:gateway).and_return(mock_gateway)
  end

  context 'race condition on index_creation' do
    before do
      exception = Elasticsearch::Transport::Transport::Errors::BadRequest.new({ type: 'index_already_exists_exception' }.to_json)
      allow(mock_gateway).to receive(:create_index!).and_raise(exception)
    end

    it 'still saves' do
      expect(mock_gateway).to receive(:save).and_return({})

      subject
    end
  end

  it 'creates the index' do
    expect(mock_gateway).to receive(:create_index!)
    allow(mock_gateway).to receive(:save).and_return({})

    subject
  end
end
