require 'rails_helper'

RSpec.describe DuplicateTasksPerContact do
  subject { described_class.new }

  let(:older_than) { nil }
  let(:task) { create(:task) }
  let!(:contact_one) { create(:contact, tasks: [task]) }
  let!(:contact_two) { create(:contact, tasks: [task]) }

  let(:fog_storage) do
    Fog.mock!
    Fog::Storage.new(provider: 'AWS',
                     aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
                     aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'))
  end
  let(:fog_dirs) { fog_storage.directories }
  let(:fog_dir) do
    fog_dirs.create(key: ENV.fetch('AWS_BUCKET'))
  end
  let!(:fog_file) do
    double('fog_file').tap do |file|
      expect(file).to receive(:save)
    end
  end
  let!(:fog_files) do
    double('fog_files').tap do |files|
      expect(files).to receive(:new) do |args|
        expect(args.keys).to include :key, :body
        fog_file
      end
    end
  end

  before do
    expect(Fog::Storage).to receive(:new).with(Hash).and_return(fog_storage)
    expect(fog_storage).to receive(:directories).and_return(fog_dirs)
    expect(fog_dirs).to receive(:get).with(String).and_return(fog_dir)
    expect(fog_dir).to receive(:files).and_return(fog_files)

    task.reload
  end

  it 'creates a duplicate task' do
    expect { subject.perform }.to change { Task.count }.from(1).to(2)
  end

  it 'ensures all Tasks have unique UUIDs' do
    subject.perform
    expect(Task.all.pluck(:uuid).uniq.size).to eq Task.count
  end

  it 'results in all Tasks having exactly one Contact' do
    subject.perform
    expect(Task.all.reject { |t| t.contacts.size == 1 }).to be_empty
  end

  it 'resuses the existing Task for the first Comment' do
    subject.perform
    contact_one.reload
    contact_two.reload

    expect(contact_one.tasks.first).to eq task
    expect(contact_two.tasks.first).not_to eq task
  end

  it 'logs the created Task IDs to S3' do
    # we will replace the default expectation for :new
    RSpec::Mocks.space.proxy_for(fog_files).reset

    expect(fog_files).to receive(:new) do |args|
      expect(args[:key]).to match(/duplicate_tasks_per_contact__.+\.log/)
      expect(args[:body]).to match(%r{workers/duplicate_tasks_per_contact\.rb})
      expect(args[:body]).to match(/^#{task.id}(?:\s\d+)+$/)
      expect(args[:body].lines[2].split(/\s/).size).to eq Task.count

      fog_file
    end

    subject.perform
  end

  context 'with comments' do
    let(:comments) { ['comment one', 'comment two'] }

    before do
      comments.each { |text| task.comments.create!(body: text) }
    end

    it 'duplicates each comment' do
      expect { subject.perform }.to change { ActivityComment.count }.from(2).to(4)

      comments.each do |text|
        expect(ActivityComment.where(body: text).count).to eq 2
      end
    end

    it 'ensures each Task has unique comments' do
      subject.perform
      new_task = Task.last
      expect((task.comments.pluck(:id) - new_task.comments.pluck(:id)).size).to eq 2
    end
  end

  context 'with a non-default time-span' do
    let(:older_than) { 1.day.ago }

    before { task.update!(created_at: 2.days.ago) }

    it 'ignores Tasks which were created too long ago' do
      expect { subject.perform(older_than) }.not_to change { Task.count }
    end
  end
end
