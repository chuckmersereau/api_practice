require 'rails_helper'

RSpec.describe Contact::NameBuilder, type: :model do
  let(:params) { {} }

  let(:builder) { Contact::NameBuilder.new(params) }

  it 'initializes' do
    expect(builder).to be_a(Contact::NameBuilder)
  end

  subject { builder.name }

  context 'nil values' do
    context 'hash param' do
      let(:params) do
        {
          first_name: nil,
          middle_name: nil,
          last_name: nil,
          spouse_first_name: nil,
          spouse_middle_name: nil,
          spouse_last_name: nil
        }
      end

      it 'builds the name' do
        expect(subject).to eq('')
      end
    end

    context 'string param' do
      let(:params) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  context 'all parts' do
    context 'hash param' do
      let(:params) do
        {
          first_name: 'First',
          middle_name: 'Middle',
          last_name: 'Last',
          spouse_first_name: 'Spousefirst',
          spouse_middle_name: 'Spousemiddle',
          spouse_last_name: 'Spouselast'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('Last and Spouselast, First Middle and Spousefirst Spousemiddle')
      end
    end

    context 'string param' do
      let(:params) { 'First Middle Last and Spousefirst Spousemiddle Spouselast' }

      it 'builds the name' do
        expect(subject).to eq('Last and Spouselast, First Middle and Spousefirst Spousemiddle')
      end
    end
  end

  context 'last name only' do
    context 'hash param' do
      let(:params) do
        {
          first_name: nil,
          middle_name: nil,
          last_name: 'Last',
          spouse_first_name: nil,
          spouse_middle_name: nil,
          spouse_last_name: nil
        }
      end

      it 'builds the name' do
        expect(subject).to eq('Last')
      end
    end

    context 'string param' do
      let(:params) { 'Last' }

      it 'builds the name' do
        expect(subject).to eq('Last')
      end
    end
  end

  context 'first name only' do
    context 'hash param' do
      let(:params) do
        {
          first_name: 'First'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('First')
      end
    end
  end

  context 'spouse first name only' do
    context 'hash param' do
      let(:params) do
        {
          spouse_first_name: 'Spousefirst'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('Spousefirst')
      end
    end
  end

  context 'spouse last name only' do
    context 'hash param' do
      let(:params) do
        {
          spouse_last_name: 'Spouselast'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('Spouselast')
      end
    end
  end

  context 'no spouse names' do
    context 'hash param' do
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

    context 'string param' do
      let(:params) { 'First Last' }

      it 'builds the name' do
        expect(subject).to eq('Last, First')
      end
    end
  end

  context 'no primary names' do
    context 'hash param' do
      let(:params) do
        {
          spouse_first_name: 'Spousefirst',
          spouse_last_name: 'Spouselast'
        }
      end

      it 'builds the name' do
        expect(subject).to eq('Spouselast, Spousefirst')
      end
    end
  end

  context 'name is nonhuman' do
    context 'string param' do
      let(:params) { ["Bob's Church", "Joe's Coffee LTD", "Joe's Coffee Ltd.", 'community school'] }

      it 'returns the input' do
        params.each do |param|
          expect(Contact::NameBuilder.new(param).name).to eq(param.titleize)
        end
      end

      it 'only looks at whole words when looking for a nonhuman name' do
        expect(Contact::NameBuilder.new('John Schurch').name).to eq('Schurch, John')
        expect(Contact::NameBuilder.new('John Church').name).to eq('John Church')
      end
    end
  end
end
