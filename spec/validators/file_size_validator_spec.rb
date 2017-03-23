require 'rails_helper'

describe FileSizeValidator do
  subject { FileSizeValidator.new(attributes: [:file], less_than: 1000).validate_each(record_double, :file, record_double.file) }

  context 'file size is less than the max' do
    let(:record_double) { double(errors: { file: [] }, file: double(size: 999)) }

    it 'does not add any errors' do
      subject
      expect(record_double.errors[:file]).to eq []
      expect(record_double.errors.keys).to eq [:file]
    end
  end

  context 'file size is more than the max' do
    let(:record_double) { double(errors: { file: [] }, file: double(size: 1001)) }

    it 'adds an error message to errors' do
      subject
      expect(record_double.errors[:file]).to eq ['File size must be less than 1000 bytes']
      expect(record_double.errors.keys).to eq [:file]
    end
  end
end
