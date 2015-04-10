require 'spec_helper'

describe Import do
  before(:each) do
    @tnt_import = double('tnt_import', import: true, xml: { 'Database' => { 'Tables' => [] } })
    TntImport.stub(:new).and_return(@tnt_import)
  end

  it "should set 'importing' to false after an import" do
    import = create(:tnt_import, importing: true)
    import.send(:import)
    import.importing.should == false
  end

  it 'should send an success email when importing completes then merge contacts and queue google sync' do
    ImportMailer.should_receive(:complete).and_return(OpenStruct.new)
    import = create(:tnt_import)
    expect(import.account_list).to receive(:merge_contacts)
    expect(import.account_list).to receive(:queue_sync_with_google_contacts)
    import.send(:import)
  end

  it "should send a failure email if there's an error" do
    import = create(:tnt_import)
    @tnt_import.should_receive(:import).and_raise('foo')

    expect do
      ImportMailer.should_receive(:failed).and_return(OpenStruct.new)
      import.send(:import)
    end.to raise_error
  end

  it 'should send a failure error but not re-raise/notify the error if the error is UnsurprisingImportError' do
    import = create(:tnt_import)
    @tnt_import.should_receive(:import).and_raise(Import::UnsurprisingImportError)

    expect do
      ImportMailer.should_receive(:failed).and_return(OpenStruct.new)
      import.send(:import)
    end.to_not raise_error
  end
end
