require 'rails_helper'

RSpec.describe DuplicateTasksPerContact do
  subject { described_class.new.perform(filter_account_list, min_contacts) }
  let(:filter_account_list) { nil }
  let(:min_contacts) { 2 }

  let(:task) { create(:task) }
  let!(:contact_one) { create(:contact, tasks: [task]) }
  let!(:contact_two) { create(:contact, tasks: [task]) }

  # These fog_ variables are just to mock out the AWS S3 service
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
    expect { subject }.to change { Task.count }.from(1).to(2)
  end

  it 'ensures all Tasks have unique UUIDs' do
    subject
    expect(Task.all.pluck(:uuid).uniq.size).to eq Task.count
  end

  it 'results in all Tasks having exactly one Contact' do
    subject
    expect(Task.all.reject { |t| t.contacts.size == 1 }).to be_empty
  end

  it 'resuses the existing Task for the first Comment' do
    subject
    contact_one.reload
    contact_two.reload

    expect(contact_one.tasks.first).to eq task
    expect(contact_two.tasks.first).not_to eq task
  end

  it 'logs the created Task IDs to S3' do
    # we will replace the default expectation for :new
    RSpec::Mocks.space.proxy_for(fog_files).reset

    expect(fog_files).to receive(:new) do |args|
      expect(args[:key]).to match(%r{^worker_results/duplicate_tasks_per_contact__.+\.log$})
      expect(args[:body]).to match(%r{workers/duplicate_tasks_per_contact\.rb})
      expect(args[:body]).to match(/^#{task.id}(?:\s\d+)+$/)
      expect(args[:body].lines[2].split(/\s/).size).to eq Task.count

      fog_file
    end

    subject
  end

  context 'with comments' do
    let(:comments) { ['comment one', 'comment two'] }

    before do
      comments.each { |text| task.comments.create!(body: text) }
    end

    it 'duplicates each comment' do
      expect { subject }.to change { ActivityComment.count }.from(2).to(4)

      comments.each do |text|
        expect(ActivityComment.where(body: text).count).to eq 2
      end
    end

    it 'ensures each Task has unique comments' do
      subject
      new_task = Task.last
      expect((task.comments.pluck(:id) - new_task.comments.pluck(:id)).size).to eq 2
    end
  end

  context 'filter by account_list with no tasks' do
    let(:account_with_no_tasks) { create(:account_list) }
    let(:filter_account_list) { account_with_no_tasks }

    it 'creates no duplicate tasks' do
      expect { subject }.not_to change { Task.count }
    end

    it 'logs the created Task IDs to S3' do
      # we will replace the default expectation for :new
      RSpec::Mocks.space.proxy_for(fog_files).reset

      expect(fog_files).to receive(:new) do |args|
        expect(args[:key]).to match(/duplicate_tasks_per_contact__.+\.log/)
        expect(args[:body]).to match(%r{workers/duplicate_tasks_per_contact\.rb})
        expect(args[:body]).to match(/^$/)

        fog_file
      end

      subject
    end
  end

  context 'filter by another account_list with separate tasks' do
    let(:another_task) { create(:task) }
    let!(:another_contact_one) { create(:contact, tasks: [another_task]) }
    let!(:another_contact_two) { create(:contact, tasks: [another_task]) }

    let(:filter_account_list) { another_task.account_list }
    before { another_task.reload }

    it 'creates only one duplicate task' do
      expect { subject }.to change { Task.count }.from(2).to(3)
    end

    it 'ensures all Tasks have unique UUIDs' do
      subject
      expect(Task.all.pluck(:uuid).uniq.size).to eq Task.count
    end

    it 'results in all Tasks having exactly one Contact' do
      subject
      expect(Task.all.reject { |t| t.contacts.size == 1 }.size).to eq 1
      expect(Task.all.reject { |t| t.contacts.size == 1 }.first).to eq task
    end

    it 'logs the created Task IDs to S3' do
      # we will replace the default expectation for :new
      RSpec::Mocks.space.proxy_for(fog_files).reset

      expect(fog_files).to receive(:new) do |args|
        expect(args[:key]).to match(%r{^worker_results/account-list-#{another_task.account_list_id}/duplicate_tasks_per_contact__.+\.log$})
        expect(args[:body]).to match(%r{workers/duplicate_tasks_per_contact\.rb})
        expect(args[:body]).to match(/^#{another_task.id}(?:\s\d+)+$/)
        expect(args[:body].lines[2].split(/\s/).size).to eq(Task.count - 1)

        fog_file
      end

      subject
    end
  end
end
