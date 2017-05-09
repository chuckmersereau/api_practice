require 'rails_helper'

describe UploadExtensionValidator do
  subject do
    UploadExtensionValidator.new(extension: 'xml', message: 'Must be xml!',
                                 attributes: [:file])
  end
  let(:import) { build(:import, source: 'tnt') }

  context 'extension is a string' do
    it 'gives a validation error for a filename with an invalid extension' do
      import = stub_import('not-xml.other')
      subject.validate(import)
      expect(import.errors[:file]).to include('Must be xml!')
    end

    it 'gives no error if extension is correct' do
      import = stub_import('valid.xml')
      subject.validate(import)
      expect(import.errors[:file]).to be_empty
    end

    it 'gives no error if extension is correct but different case' do
      import = stub_import('VALID.XML')
      subject.validate(import)
      expect(import.errors[:file]).to be_empty
    end
  end
  context 'extension is an array [tntdatasync tntmpd]' do
    subject do
      UploadExtensionValidator.new(extension: %w(tntdatasync tntmpd), message: 'Must be tnt output!',
                                   attributes: [:file])
    end
    it 'gives a validation error for a filename with an invalid extension' do
      import = stub_import('not-tnt.other')
      subject.validate(import)
      expect(import.errors[:file]).to include('Must be tnt output!')
    end

    context 'extension is tntdatasync' do
      it 'gives no error if extension is tntdatasync' do
        import = stub_import('valid.tntdatasync')
        subject.validate(import)
        expect(import.errors[:file]).to be_empty
      end
      it 'gives no error if extension is tntdatasync but different case' do
        import = stub_import('VALID.TNTDATASYNC')
        subject.validate(import)
        expect(import.errors[:file]).to be_empty
      end
    end
    context 'extension is tntmpd' do
      it 'gives no error if extension is tntmpd' do
        import = stub_import('valid.tntmpd')
        subject.validate(import)
        expect(import.errors[:file]).to be_empty
      end
      it 'gives no error if extension is tntmpd but different case' do
        import = stub_import('VALID.TNTMPD')
        subject.validate(import)
        expect(import.errors[:file]).to be_empty
      end
    end
  end

  def stub_import(filename)
    file = double(path: filename)
    import = double(errors: { file: [] }, file: file)
    allow(import).to receive(:read_attribute_for_validation).with(:file) { file }
    import
  end
end
