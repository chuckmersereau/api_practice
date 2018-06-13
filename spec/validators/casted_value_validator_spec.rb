require 'spec_helper'
require './app/validators/casted_value_validator'

RSpec.describe CastedValueValidator, type: :validator do
  describe 'DATE_FIELD_ENDINGS' do
    it 'returns the correct values' do
      expect(CastedValueValidator::DATE_FIELD_ENDINGS)
        .to eq %w(_at _date _range)
    end
  end

  describe '#validate!' do
    context 'when the date provided is a date, datetime, or date range' do
      it "is nil when the attribute doesn't end with date endings" do
        result = CastedValueValidator.validate!(
          attribute: 'not_in_date_endings',
          value: DateTime.new.utc
        )

        expect(result).to be_nil
      end

      it 'is valid when using a date range' do
        result = CastedValueValidator.validate!(
          attribute: 'month_range',
          value: (Date.yesterday..Date.today)
        )

        expect(result).to be_truthy
      end

      date_values = {
        date: Date.new,
        datetime: DateTime.new.utc,
        date_range: Date.new(2017, 2, 10)..Date.new(2017, 3, 10)
      }

      date_values.each do |label, value|
        it "is true when the attribute ends with date endings & is a #{label}" do
          result = CastedValueValidator.validate!(
            attribute: 'created_at',
            value: value
          )

          expect(result).to eq true
        end
      end
    end

    context 'when the date provided is not a date' do
      it "is nil when the attribute doesn't end with date endings" do
        result = CastedValueValidator.validate!(
          attribute: 'not_in_date_endings',
          value: DateTime.new.utc
        )

        expect(result).to be_nil
      end

      date_values = {
        date: 'not a date',
        datetime: 'not a datetime',
        date_range: 'not a date range'
      }

      date_values.each do |label, value|
        it "is true when the attribute ends with date endings & is a #{label}" do
          expect do
            CastedValueValidator.validate!(
              attribute: 'created_at',
              value: value
            )
          end.to raise_error(CastedValueValidator::DateTimeCastingError)
        end
      end
    end
  end
end
