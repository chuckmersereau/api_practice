require 'rails_helper'

describe Import do
  before(:each) do
    @tnt_import = double('tnt_import', import: false, xml: { 'Database' => { 'Tables' => [] } })
    allow(TntImport).to receive(:new).and_return(@tnt_import)
  end

  Import::SOURCES.each do |source|
    describe "#source_#{source}?" do
      it "returns true if source is #{source} and false otherwise" do
        import = build(:import, source: nil)
        expect { import.source = source }.to change { import.send("source_#{source}?") }.from(false).to(true)
      end
    end
  end

  describe '#user_friendly_source' do
    let(:import) { build(:import, in_preview: true) }

    it 'returns a human readable version of the source for each source' do
      (Import::SOURCES - %w(csv tnt tnt_data_sync)).each do |source|
        import.source = source
        expect(import.user_friendly_source).to eq source.humanize
      end
      %w(csv).each do |source|
        import.source = source
        expect(import.user_friendly_source).to eq source.upcase
      end
      %w(tnt tnt_data_sync).each do |source|
        import.source = source
        expect(import.user_friendly_source).to eq source.titleize
      end
    end
  end

  describe '#file=' do
    it 'resets local attributes related to the file' do
      import = create(:csv_import, in_preview: true)
      import.file_headers = { test: 'test' }
      import.file_constants = { test: 'test' }
      import.file_row_samples = [:test]
      import.file_row_failures = [:test]
      expect { import.file = File.new(Rails.root.join('spec/fixtures/sample_csv_with_custom_headers.csv')) }
        .to  change { import.file_headers }.to({})
        .and change { import.file_constants }.to({})
        .and change { import.file_row_samples }.to([])
        .and change { import.file_row_failures }.to([])
    end
  end

  context 'tags' do
    let(:import) { build(:import, tags: 'a,b,c,d') }

    describe '#tags' do
      it 'returns tags as an Array' do
        expect(import.tags).to be_a Array
        expect(import.tags).to eq %w(a b c d)
      end
    end

    describe '#tags=' do
      it 'sets tags from an Array' do
        import.tags = %w(1 2 3)
        expect(import.tags).to eq %w(1 2 3)
        import.save!
        import.reload
        expect(import.tags).to eq %w(1 2 3)
      end

      it 'accepts nil' do
        import.tags = nil
        expect(import.tags).to eq []
      end
    end

    describe '#tag_list' do
      it 'returns tags as a comma delimited String' do
        expect(import.tag_list).to be_a String
        expect(import.tag_list).to eq 'a,b,c,d'
      end
    end

    describe '#tag_list=' do
      it 'sets tags from a comma delimited String' do
        import.tag_list = '1,2,3'
        expect(import.tag_list).to eq '1,2,3'
        import.save!
        import.reload
        expect(import.tag_list).to eq '1,2,3'
      end

      it 'accepts nil' do
        import.tag_list = nil
        expect(import.tag_list).to eq ''
      end
    end
  end

  it "should set 'importing' to false after an import" do
    import = create(:tnt_import, importing: true)
    import.send(:import)
    expect(import.importing).to eq(false)
  end

  it 'should send an success email when importing completes then merge contacts and queue google sync' do
    expect_delayed_email(ImportMailer, :success)
    import = create(:tnt_import)
    expect(import.account_list).to receive(:async_merge_contacts)
    expect(import.account_list).to receive(:queue_sync_with_google_contacts)
    import.send(:import)
  end

  it "should send a failure email if there's an error and not re-raise it" do
    import = create(:tnt_import)
    expect(@tnt_import).to receive(:import).and_raise('foo')
    expect_delayed_email(ImportMailer, :failed)
    expect(Rollbar).to receive(:error)

    expect do
      import.send(:import)
    end.to_not raise_error
  end

  it 'should send a failure error but not re-raise the error if the error is UnsurprisingImportError' do
    Sidekiq::Testing.inline!
    import = create(:tnt_import)
    expect(@tnt_import).to receive(:import).and_raise(Import::UnsurprisingImportError)
    expect_delayed_email(ImportMailer, :failed)
    expect(Rollbar).to receive(:info)

    expect do
      import.send(:import)
    end.to_not raise_error
  end

  it 'passes an exception on to the callback handler on failure' do
    Sidekiq::Testing.inline!
    import = create(:tnt_import)
    error = StandardError.new
    expect(@tnt_import).to receive(:import).and_raise(error)
    expect_any_instance_of(ImportCallbackHandler).to receive(:handle_failure).with(exception: error)

    import.send(:import)
  end

  describe '#queue_import' do
    it 'queues an import when saved' do
      expect { create(:import) }.to change(Import.jobs, :size).from(0).to(1)
    end

    it 'does not requeue an import that was already queued' do
      import = build(:import)
      expect { import.save }.to change(Import.jobs, :size).from(0).to(1)
      Import.clear
      expect { import.reload.save }.to_not change(Import.jobs, :size).from(0)
    end

    it 'sets queued_for_import_at after queueing the import' do
      travel_to Time.current do
        import = build(:import)
        expect { import.save }.to change { import.queued_for_import_at }.from(nil).to(Time.current)
      end
    end

    it 'does not queue import on destroy' do
      import = create(:import, in_preview: true)
      import.update_columns(queued_for_import_at: nil, in_preview: false)
      expect { import.destroy }.to_not change(Import.jobs, :size)
    end
  end

  it 'should finish import if sending mail fails' do
    expect(ImportMailer).to receive(:delay).and_raise(StandardError)

    import = create(:tnt_import)
    expect(import.account_list).to receive(:async_merge_contacts)
    expect(import.account_list).to receive(:queue_sync_with_google_contacts)
    import.send(:import)
  end

  context 'in_preview' do
    it 'does not queue an import' do
      expect { create(:csv_import, in_preview: true) }.to_not change(Import.jobs, :size).from(0)
    end

    it 'does not validate csv headers' do
      import = build(:csv_import_custom_headers, in_preview: true)
      expect(import.valid?).to eq true
      import.in_preview = false
      expect(import.valid?).to eq false
    end
  end

  it 'validates size of file' do
    import = build(:import)
    allow(import.file).to receive(:size).and_return(Import::MAX_FILE_SIZE_IN_BYTES + 1)
    expect(import.valid?).to eq false
    expect(import.errors[:file]).to eq ["File size must be less than #{Import::MAX_FILE_SIZE_IN_BYTES} bytes"]
  end

  describe '#file_path' do
    it 'returns the file_path' do
      import = create(:csv_import, in_preview: true)
      expect(import.file_path).to eq(import.file.file.file)
      expect(import.file_path).to end_with('sample_csv_to_import.csv')
    end

    it 'returns the file path as a cached file, not a stored file' do
      import = create(:csv_import, in_preview: true)
      expect(import.file_path).to_not include(import.file.store_path)
      expect(import.file_path).to end_with(import.file.cache_name)
    end

    it 'caches the stored file' do
      import = create(:csv_import, in_preview: true)
      expect_any_instance_of(CarrierWave::Uploader::Base).to receive(:cache_stored_file!)
      import.file_path
    end

    it 'it does not recache file on subsequent calls' do
      import = create(:csv_import, in_preview: true)
      import.file_path
      expect_any_instance_of(CarrierWave::Uploader::Base).to_not receive(:cache_stored_file!)
      import.file_path
    end

    it 'returns nil if there is no file' do
      expect(Import.new.file_path).to eq nil
    end
  end

  it 'allows no file_constants' do
    import = create(:csv_import, in_preview: true)
    import.file_constants = nil
    import.in_preview = false
    import.valid?
    expect(import.errors[:file_constants].present?).to eq(false)
  end
end
