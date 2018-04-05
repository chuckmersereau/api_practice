require 'rails_helper'

describe TntImport::TasksImport do
  let(:user) { create(:user) }
  let(:tnt_import) { create(:tnt_import, override: true, user: user) }
  let(:tnt3_2_xml) { File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_broad.xml')) }
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }
  let(:contacts) do
    xml.tables['TaskContact'].map do |row|
      create(:contact, tnt_id: row['ContactID'])
    end
  end
  let(:contact_ids) { Hash[contacts.map { |c| [c.tnt_id.to_s, c.id] }] }
  subject { described_class.new(tnt_import, contact_ids, xml) }

  before do
    stub_smarty_streets
  end

  describe '#import' do
    context 'no xml task data' do
      let(:xml) { double(tables: {}) }
      let(:contact_ids) { {} }

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

    context 'with WhatsApp task type' do
      before do
        xml.tables['Task'].first['TaskTypeID'] = '180'
      end

      it 'includes a comment' do
        expect { subject.import }.to change { Task.count }.from(0).to(1)
        task = Task.last
        expect(task.activity_type).to eq 'Text Message'
        expect(Task.last.comments.pluck(:body)).to include 'This task was given the type "WhatsApp" in TntConnect.'
      end
    end

    context 'with Present task type' do
      before do
        xml.tables['Task'].first['TaskTypeID'] = '160'
      end

      it 'includes a comment' do
        expect { subject.import }.to change { Task.count }.from(0).to(1)
        task = Task.last
        expect(task.activity_type).to eq nil
        expect(Task.last.comments.pluck(:body)).to include 'This task was given the type "Present" in TntConnect.'
      end
    end

    context 'with Categories' do
      it 'includes tags for multiple categories' do
        xml.tables['Task'].first['Categories'] = 'test, Another Category'

        expect { subject.import }.to change { Task.count }.from(0).to(1)

        task = Task.last
        expect(task.tag_list).to include 'test', 'another category'
      end
    end

    context 'with task assigned to' do
      let(:user_row) { xml.tables['User'].first }

      before do
        tnt_import.file = tnt3_2_xml
        # only one task
        xml.tables['Task'] = xml.tables['Task'][0..0]
        xml.tables['Task'].first['AssignedToUserID'] = user_row['id']
      end

      it 'includes a tag' do
        expect { subject.import }.to change { Task.count }
        task = Task.last
        expect(task.tag_list).to include user_row['UserName'].downcase
      end
    end

    context 'with LoggedByUserID' do
      let(:user_row) { xml.tables['User'].first }

      before do
        tnt_import.file = tnt3_2_xml
        # only one task
        xml.tables['Task'] = xml.tables['Task'][0..0]
        xml.tables['Task'].first['LoggedByUserID'] = user_row['id']
        # mark task completed
        xml.tables['Task'].first['Status'] = '2'
      end

      it 'adds user to comment' do
        expect { subject.import }.to change(ActivityComment, :count)

        task = Task.last
        comments = task.comments.pluck(:body)
        expect(comments).to include "Completed By: #{user_row['UserName']}"
      end
    end

    context 'with task campaign' do
      before do
        tnt_import.file = File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_broad.xml'))
        # only one task
        xml.tables['Task'] = xml.tables['Task'][0..0]
        xml.tables['Task'].first['CampaignID'] = xml.tables['Campaign'].first['id']
      end

      it 'includes a tag' do
        expect { subject.import }.to change { Task.count }
        task = Task.last
        expect(task.tag_list).to include xml.tables['Campaign'].first['Description'].downcase
      end
    end

    context 'with multiple task contacts per task' do
      let(:tnt_import) do
        create(:tnt_import_with_multiple_task_contacts, override: true,
                                                        user: user)
      end

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

    context 'with comments' do
      let(:unsupported_tnt_task_id) { TntImport::TntCodes::UNSUPPORTED_TNT_TASK_CODES.keys.first }
      let(:task_row) { xml.tables['Task'].first }
      let(:note) { 'A non-notable note' }

      before do
        task_row['Notes'] = note
      end

      it 'adds a comment for a tnt notes' do
        expect do
          subject.import
        end.to change(ActivityComment, :count).from(0).to(1)
      end

      it 'does not add a duplicate comment for a note' do
        subject.import
        task = Task.first

        expect do
          subject.import
        end.to_not change { task.reload.comments.count }
      end

      it 'adds a comment for an unsupported tnt task type' do
        task_row['TaskTypeID'] = unsupported_tnt_task_id

        expect do
          subject.import
        end.to change(ActivityComment, :count).from(0).to(2)
        expect(Task.first.comments.where(body: 'This task was given the type "Present" in TntConnect.').count).to eq(1)
      end
    end
  end
end
