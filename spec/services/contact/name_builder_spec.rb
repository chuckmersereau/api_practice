require 'rails_helper'

RSpec.describe Contact::NameBuilder, type: :model do
  let(:params) { {} }

  let(:builder) { Contact::NameBuilder.new(params) }

  it 'initializes' do
    expect(builder).to be_a(Contact::NameBuilder)
  end

  describe '#name' do
    subject { builder.name }

    context 'nil values' do
      let(:params) do
        {
          first_name: nil,
          last_name: nil,
          spouse_first_name: nil,
          spouse_last_name: nil
        }
      end

      it 'builds the name' do
        expect(subject).to eq('')
      end
    end

    context 'all parts' do
      let(:params) do
        {
          first_name: 'First',
          last_name: 'Last',
          spouse_first_name: 'SpouseFirst',
          spouse_last_name: 'SpouseLast'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('Last and SpouseLast, First and SpouseFirst')
      end
    end

    context 'last name only' do
      let(:params) do
        {
          first_name: nil,
          last_name: 'Last',
          spouse_first_name: nil,
          spouse_last_name: nil
        }
      end

      it 'builds the name' do
        expect(subject).to eq('Last')
      end
    end

    context 'first name only' do
      let(:params) do
        {
          first_name: 'First'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('First')
      end
    end

    context 'spouse first name only' do
      let(:params) do
        {
          spouse_first_name: 'SpouseFirst'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('SpouseFirst')
      end
    end

    context 'spouse last name only' do
      let(:params) do
        {
          spouse_last_name: 'SpouseLast'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('SpouseLast')
      end
    end

    context 'no spouse names' do
      let(:params) do
        {
          first_name: 'First',
          last_name: 'Last'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('Last, First')
      end
    end

    context 'no primary names' do
      let(:params) do
        {
          spouse_first_name: 'SpouseFirst',
          spouse_last_name: 'SpouseLast'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('SpouseLast, SpouseFirst')
      end
    end
  end
end
