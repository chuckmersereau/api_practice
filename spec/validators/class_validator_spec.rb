require 'rails_helper'

describe ClassValidator do
  subject do
    ClassValidator.new(attributes: [:tester], is_a: String).validate_each(record_double, :tester, record_double.tester)
  end

  context 'valid' do
    let(:record_double) { double(errors: { tester: [] }, tester: 'A String') }

    it 'does not add any errors' do
      subject
      expect(record_double.errors[:tester]).to eq []
    end
  end

  context 'invalid' do
    let(:record_double) { double(errors: { tester: [] }, tester: ['A String inside an Array']) }

    it 'adds errors' do
      subject
      expect(record_double.errors[:tester]).to eq ['should be a String']
    end
  end

  context 'allow_nil is unspecified' do
    let(:record_double) { double(errors: { tester: [] }, tester: nil) }

    it 'adds errors' do
      subject
      expect(record_double.errors[:tester]).to eq ['should be a String']
    end
  end

  context 'allow_nil is false' do
    subject do
      ClassValidator.new(attributes: [:tester], is_a: String, allow_nil: false)
                    .validate_each(record_double, :tester, record_double.tester)
    end

    let(:record_double) { double(errors: { tester: [] }, tester: nil) }

    it 'adds errors if attribute is nil' do
      subject
      expect(record_double.errors[:tester]).to eq ['should be a String']
    end
  end

  context 'allow_nil is true' do
    subject do
      ClassValidator.new(attributes: [:tester], is_a: String, allow_nil: true)
                    .validate_each(record_double, :tester, record_double.tester)
    end

    let(:record_double) { double(errors: { tester: [] }, tester: nil) }

    it 'does not add any errors if attributes is nil' do
      subject
      expect(record_double.errors[:tester]).to eq []
    end
  end
end
