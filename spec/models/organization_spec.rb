require 'rails_helper'

describe Organization do
  it 'should return the org name for to_s' do
    expect(described_class.new(name: 'foo').to_s).to eq('foo')
  end

  describe 'guess_country' do
    context 'name does not convert to country' do
      subject { build(:organization, name: 'No match here') }

      it 'returns nil if no match found' do
        expect(subject.guess_country).to be_nil
      end
    end

    context 'name contains country name' do
      subject { build(:organization, name: 'Cru - Panama') }

      it 'finds a country after Parent org name' do
        expect(subject.guess_country).to eq 'Panama'
      end
    end

    context 'name contains country abbreviations' do
      context 'CAN' do
        subject { build(:organization, name: 'CAN') }

        it 'expands abbreviations' do
          expect(subject.guess_country).to eq 'Canada'
        end
      end

      context 'USA' do
        subject { build(:organization, name: 'Gospel For Asia   USA') }

        it 'expands abbreviations' do
          expect(subject.guess_country).to eq 'United States'
        end
      end
    end
  end

  context '#guess_locale' do
    context 'country is blank' do
      subject { build(:organization, country: nil) }

      it 'returns en' do
        expect(subject.guess_locale).to eq 'en'
      end
    end

    context 'country does not exist' do
      subject { build(:organization, country: 'Not-A-Country') }

      it 'returns en' do
        expect(subject.guess_locale).to eq 'en'
      end
    end

    context 'country is set' do
      subject { build(:organization, country: 'France') }

      it 'returns locale of country' do
        expect(subject.guess_locale).to eq 'fr'
      end
    end
  end
end
