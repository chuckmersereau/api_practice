require 'rails_helper'

RSpec.describe Audited::AuditElastic, type: :model do
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
  subject { Audited::AuditElastic.new(audit_attributes) }

  describe '#user' do
    it 'returns user model' do
      expect(subject.user).to eq user
    end
  end

  describe '#undo' do
    it 'changes back a value' do
      expect { subject.undo }.to change { audited.reload.first_name }.to('Steve')
    end

    it 'saves an audit with comment' do
      allow_any_instance_of(audited.class).to receive(:system_auditing_enabled).and_return(true)
      subject
      comment = 'Test'

      expect { subject.undo(comment) }.to change(AuditChangeWorker.jobs, :size).by(1)
      expect(AuditChangeWorker.jobs.dig(-1, 'args', 0, 'comment')).to eq comment
    end
  end
end
