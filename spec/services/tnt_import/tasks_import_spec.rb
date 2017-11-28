require 'rails_helper'

describe TntImport::TasksImport do
  let(:user) { create(:user) }
  let(:tnt_import) { create(:tnt_import, override: true, user: user) }
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }
  let(:contact_ids) { {} }
  subject { described_class.new(tnt_import, contact_ids, xml) }

  before do
    stub_smarty_streets
  end

  describe '#import' do
    context 'no xml task data' do
      let(:xml) { double(tables: {}) }
      it 'returns empty hash' do
        expect(subject.import).to eq(nil)
      end
    end

    context 'with data change task types' do
      before do
        xml.tables['Task'].first['TaskTypeID'] = '190'
      end

      it 'skips change data task items' do
        expect { subject.import }.to_not change { Task.count }
      end
    end

    context 'with multiple task contacts per task' do
      let(:tnt_import) do
        create(:tnt_import_with_multiple_task_contacts, override: true,
                                                        user: user)
      end

      let(:contacts) do
        xml.tables['TaskContact'].map do |row|
          create(:contact, tnt_id: row['ContactID'])
        end
      end

      let(:contact_ids) { Hash[contacts.map { |c| [c.tnt_id.to_s, c.id] }] }

      it 'creates one for each contact' do
        expect { subject.import }.to change { Task.count }.by(contacts.size)
      end

      it 'creates tasks with only a single associated contact' do
        subject.import
        Task.all.each { |task| expect(task.contacts.size).to eq 1 }
      end

      it 'creates a unique task record for each contact' do
        subject.import

        tasks = Contact.all.flat_map(&:tasks)
        expect(tasks.size).to eq tasks.uniq.size
      end

      context 'a Task with the remote ID already exists' do
        let!(:preexisting_task) do
          create(:task, remote_id: xml.tables['Task'].first['id'],
                        source: 'tnt', account_list: tnt_import.account_list)
        end

        it 'creates copies for the other contacts' do
          expect { subject.import }.to change { Task.count }.by(contacts.size - 1)
        end

        it 'creates tasks with only a single associated contact' do
          subject.import
          Task.all.each { |task| expect(task.contacts.size).to eq 1 }
        end

        it 'creates a unique task record for each contact' do
          subject.import

          tasks = Contact.all.flat_map(&:tasks)
          expect(tasks.size).to eq tasks.uniq.size
        end
      end
    end
  end
end
