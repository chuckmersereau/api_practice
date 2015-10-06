require 'spec_helper'

describe UploadExtensionValidator do
  subject do
    UploadExtensionValidator.new(extension: 'xml', message: 'Must be xml!',
                                 attributes: [:file])
  end
  let(:import) { build(:import, source: 'tnt') }

  it 'gives a validation error for a filename with an invalid extension' do
    import = stub_import('not-xml.other')
    subject.validate(import)
    expect(import.errors[:base]).to include('Must be xml!')
  end

  it 'gives no error if extension is correct' do
    import = stub_import('valid.xml')
    subject.validate(import)
    expect(import.errors[:base]).to be_empty
  end

  it 'gives no error if extension is correct but different case' do
    import = stub_import('VALID.XML')
    subject.validate(import)
    expect(import.errors[:base]).to be_empty
  end

  def stub_import(filename)
    import = double(errors: { base: [] })
    file = double(filename: filename)
    allow(import).to receive(:read_attribute_for_validation).with(:file) { file }
    import
  end
end
