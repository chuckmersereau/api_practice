require 'rails_helper'

describe TntImport::HistoryImport do
  let(:user) { create(:user) }
  let(:tnt_import) { create(:tnt_import, override: true, user: user) }
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }
  let(:contacts) do
    xml.tables['HistoryContact']&.map do |row|
      create(:contact, tnt_id: row['ContactID'])
    end || {}
  end
  let(:contact_ids) { Hash[contacts.map { |c| [c.tnt_id.to_s, c.id] }] }

  subject { TntImport::HistoryImport.new(tnt_import, contact_ids, xml) }

  before do
    stub_smarty_streets
  end

  describe '#import' do
    context 'no xml history data' do
      let(:xml) { double(tables: {}) }

      it 'returns empty hash' do
        expect(subject.import).to eq({})
      end
    end

    context 'with data change task types' do
      before do
        xml.tables['History'].first['TaskTypeID'] = '190'
      end

      it 'skips change data history items' do
        expect { subject.import }.to_not change { Task.count }
      end
    end

    context 'with appeal mapping' do
      it 'returns mapping of contacts to appeal ids' do
        appeal_id = xml.tables['Appeal'].first['id']
        xml.tables['History'].first['AppealID'] = appeal_id

        expect(subject.import).to eq(appeal_id => contact_ids.values)
      end
    end

    context 'with multiple task contacts per task' do
      let(:tnt_import) do
        create(:tnt_import_with_multiple_task_contacts, override: true, user: user)
      end

      it 'creates one for each contact' do
        expect { subject.import }.to change { Task.count }.by(contacts.size)
      end

      it 'creates tasks with only a single associated contact' do
        subject.import
        Task.all.each { |task| expect(task.contacts.size).to eq 1 }
      end
    end

    it 'does not increment the tasks counts' do
      expect(contacts.count).to be 1
      contact = contacts.first

      expect { subject.import }.to change { contact.tasks.count }.by(1).and change { contact.uncompleted_tasks_count }.by(0)
    end
  end
end
