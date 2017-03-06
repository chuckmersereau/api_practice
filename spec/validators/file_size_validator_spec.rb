require 'rails_helper'

describe FileSizeValidator do
  subject { FileSizeValidator.new.validate(record_double) }

  context 'file size is less than the max' do
    let(:record_double) { double(errors: { base: [] }, file: double(size: FileSizeValidator::MAX_FILE_SIZE_IN_BYTES - 1)) }

    it 'does not add any errors' do
      subject
      expect(record_double.errors[:base]).to eq []
      expect(record_double.errors.keys).to eq [:base]
    end
  end

  context 'file size is more than the max' do
    let(:record_double) { double(errors: { base: [] }, file: double(size: FileSizeValidator::MAX_FILE_SIZE_IN_BYTES + 1)) }

    it 'adds an error message to errors base' do
      subject
      expect(record_double.errors[:base]).to eq ['File size must be less than 10000000 bytes']
      expect(record_double.errors.keys).to eq [:base]
    end
  end
end
