require 'spec_helper'

RSpec.describe RecordsWithSpecialDayBetweenDatesFinder, type: :concern do
  let(:scope)      { Person }
  let(:attribute)  { :birthday }

  describe '#initialize' do
    let(:start_date) { 1.month.ago }
    let(:end_date)   { 1.month.from_now }

    it 'initializes with a scope, attribute, start_date and end_date' do
      finder = RecordsWithSpecialDayBetweenDatesFinder.new(
        scope: scope,
        attribute: attribute,
        start_date: start_date,
        end_date: end_date
      )

      expect(finder.scope).to      eq scope
      expect(finder.attribute).to  eq attribute
      expect(finder.start_date).to eq start_date
      expect(finder.end_date).to   eq end_date
    end

    context 'when start_date is after end_date' do
      it 'raises an error' do
        arguments = {
          scope: scope,
          attribute: attribute,
          start_date: 1.month.from_now,
          end_date: Date.current
        }

        expect { RecordsWithSpecialDayBetweenDatesFinder.new(arguments) }
          .to raise_error(ArgumentError)
          .with_message('start_date cannot take place after end_date')
      end
    end
  end

  describe 'Dynamic #attribute based values' do
    let(:anniversary_args) do
      {
        scope: scope,
        attribute: :anniversary,
        start_date: Date.current,
        end_date: Date.current
      }
    end

    let(:birthday_args) do
      {
        scope: scope,
        attribute: :birthday,
        start_date: Date.current,
        end_date: Date.current
      }
    end

    let(:anniversary_finder) do
      RecordsWithSpecialDayBetweenDatesFinder.new(anniversary_args)
    end

    let(:birthday_finder) do
      RecordsWithSpecialDayBetweenDatesFinder.new(birthday_args)
    end

    describe '#attribute_day' do
      it 'is the correct interpolated value based on attribute' do
        expect(anniversary_finder.attribute_day).to eq :anniversary_day
        expect(birthday_finder.attribute_day).to    eq :birthday_day
      end
    end

    describe '#attribute_month' do
      it 'is the correct interpolated value based on attribute' do
        expect(anniversary_finder.attribute_month).to eq :anniversary_month
        expect(birthday_finder.attribute_month).to    eq :birthday_month
      end
    end
  end

  describe '#find' do
    let!(:person_with_birthday_on_christmas_eve) do
      date = '2016-12-24'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let!(:person_with_birthday_on_new_years_eve) do
      date = '2016-12-31'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let!(:person_with_birthday_on_valentines) do
      date = '2017-02-14'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let!(:person_with_birthday_on_fathers_day) do
      date = '2017-03-19'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let(:christmas_day_2016)   { '2016-12-25'.to_date }
    let(:st_patricks_day_2017) { '2017-03-17'.to_date }

    let(:finder) do
      arguments = {
        scope: scope,
        attribute: attribute,
        start_date: christmas_day_2016,
        end_date: st_patricks_day_2017
      }

      RecordsWithSpecialDayBetweenDatesFinder.new(arguments)
    end

    it 'finds the correct records' do
      results = finder.find

      expect(results).to include person_with_birthday_on_new_years_eve
      expect(results).to include person_with_birthday_on_valentines

      expect(results).not_to include person_with_birthday_on_christmas_eve
      expect(results).not_to include person_with_birthday_on_fathers_day
    end
  end

  describe '#query_arguments' do
    let(:start_date) { '2016-01-01'.to_date }
    let(:end_date)   { '2017-01-01'.to_date }

    let(:finder) do
      arguments = {
        scope: scope,
        attribute: attribute,
        start_date: start_date,
        end_date: end_date
      }

      RecordsWithSpecialDayBetweenDatesFinder.new(arguments)
    end

    it 'returns a hash of arguments sent to be evaluated by the query' do
      expected_arguments = {
        start_year: 2016,
        end_year: 2017,
        start_date: start_date,
        end_date: end_date
      }

      expect(finder.query_arguments).to eq expected_arguments
    end
  end
end
