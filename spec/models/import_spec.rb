require 'rails_helper'

describe Import do
  before(:each) do
    @tnt_import = double('tnt_import', import: true, xml: { 'Database' => { 'Tables' => [] } })
    allow(TntImport).to receive(:new).and_return(@tnt_import)
  end

  it "should set 'importing' to false after an import" do
    import = create(:tnt_import, importing: true)
    import.send(:import)
    expect(import.importing).to eq(false)
  end

  it 'should send an success email when importing completes then merge contacts and queue google sync' do
    expect(ImportMailer).to receive(:complete).and_return(OpenStruct.new)
    import = create(:tnt_import)
    expect(import.account_list).to receive(:merge_contacts)
    expect(import.account_list).to receive(:queue_sync_with_google_contacts)
    import.send(:import)
  end

  it "should send a failure email if there's an error" do
    import = create(:tnt_import)
    expect(@tnt_import).to receive(:import).and_raise('foo')

    expect do
      expect(ImportMailer).to receive(:failed).and_return(OpenStruct.new)
      import.send(:import)
    end.to raise_error('foo')
  end

  it 'should send a failure error but not re-raise/notify the error if the error is UnsurprisingImportError' do
    import = create(:tnt_import)
    expect(@tnt_import).to receive(:import).and_raise(Import::UnsurprisingImportError)

    expect do
      expect(ImportMailer).to receive(:failed).and_return(OpenStruct.new)
      import.send(:import)
    end.to_not raise_error
  end

  it 'queues an import when saved' do
    expect { create(:csv_import) }.to change(Import.jobs, :size).from(0).to(1)
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

  context 'assigning file headers from csv file' do
    it 'assigns file_headers when setting file' do
      expect(build(:csv_import_custom_headers).file_headers).to eq 'name,fname,lname,spouse_fname,spouse_lname,greeting,envelope_greeting,street,city,' \
        'state,zipcode,country,status,amount,frequency,newsletter,received,tags,email,spouse_email,phone,spouse_phone,note'
    end

    it 'assigns file_headers to nil if file is nil' do
      expect(build(:csv_import_custom_headers, file: nil).file_headers).to be_blank
    end
  end

  it 'validates size of file' do
    import = build(:import)
    allow(import.file).to receive(:size).and_return(FileSizeValidator::MAX_FILE_SIZE_IN_BYTES + 1)
    expect(import.valid?).to eq false
    expect(import.errors[:base]).to eq ['File size must be less than 10000000 bytes']
  end
end
