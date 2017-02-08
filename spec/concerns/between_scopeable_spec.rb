require 'rails_helper'

RSpec.describe BetweenScopeable, type: :concern do
  describe '#with_`attribute`_this_week' do
    let!(:person_with_birthday_last_week) do
      date = (Date.current - 1.week).end_of_week

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let!(:person_with_birthday_this_week) do
      date = Date.current

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let!(:person_with_birthday_next_week) do
      date = (Date.current + 1.week).beginning_of_week

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    context 'without passing in a specific week start_date' do
      let(:results) do
        Person.with_birthday_this_week
      end

      it 'adds a scope for finding records within this current week' do
        expect(results).not_to include person_with_birthday_last_week
        expect(results).to     include person_with_birthday_this_week
        expect(results).not_to include person_with_birthday_next_week
      end
    end

    context 'with passing in a specific week start_date' do
      let(:next_week) { (Date.current + 1.week).beginning_of_week }

      let(:results) do
        Person.with_birthday_this_week(next_week)
      end

      it 'adds a scope for finding records within this current week' do
        expect(results).not_to include person_with_birthday_last_week
        expect(results).not_to include person_with_birthday_this_week
        expect(results).to include person_with_birthday_next_week
      end
    end
  end

  describe '#with_`attribute`_in_same_month_between_two_dates' do
    let(:start_date) { '2017-02-10'.to_date }
    let(:end_date)   { '2017-02-20'.to_date }

    let!(:person_with_birthday_on_toothache_day) do
      date = '2017-02-09'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let!(:person_with_birthday_on_valentines_day) do
      date = '2017-02-14'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let!(:person_with_birthday_on_card_reading_day) do
      date = '2017-02-21'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let(:results) do
      Person
        .with_birthday_in_same_month_between_two_dates(start_date, end_date)
    end

    it 'finds records within the same month between two dates' do
      expect(results).not_to include(person_with_birthday_on_toothache_day)
      expect(results).to     include(person_with_birthday_on_valentines_day)
      expect(results).not_to include(person_with_birthday_on_card_reading_day)
    end

    it 'raises an error if the start_date is after the end_date' do
      start_date = Date.current
      end_date = start_date - 1.day

      expect do
        Person
          .with_birthday_in_same_month_between_two_dates(start_date, end_date)
      end.to raise_error(ArgumentError)
        .with_message('start_date cannot take place after end_date')
    end

    it "raises an error if the start_date and end_date aren't in same month" do
      start_date = Date.current
      end_date = Date.current + 1.month

      expect do
        Person
          .with_birthday_in_same_month_between_two_dates(start_date, end_date)
      end.to raise_error(ArgumentError)
        .with_message('dates must be in the same month')
    end
  end

  describe '#with_`attribute`_in_neighboring_months_between_two_dates' do
    let(:start_date)       { '2016-12-25'.to_date }
    let(:end_date)         { '2017-01-02'.to_date }

    let!(:person_with_birthday_on_christmas_eve) do
      date = '2016-02-24'.to_date

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

    let!(:person_with_birthday_on_new_years_day) do
      date = '2017-01-01'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let!(:person_with_birthday_on_festival_of_sleep_day) do
      date = '2017-01-03'.to_date

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let(:results) do
      Person
        .with_birthday_in_neighboring_months_between_two_dates(start_date, end_date)
    end

    it 'finds records within neighboring months between two dates' do
      expect(results).not_to include(person_with_birthday_on_christmas_eve)
      expect(results).to     include(person_with_birthday_on_new_years_eve)
      expect(results).to     include(person_with_birthday_on_new_years_day)
      expect(results).not_to include(person_with_birthday_on_festival_of_sleep_day)
    end

    it 'raises an error if the start_date is after the end_date' do
      start_date = Date.current
      end_date = start_date - 1.day

      expect do
        Person
          .with_birthday_in_neighboring_months_between_two_dates(start_date, end_date)
      end.to raise_error(ArgumentError)
        .with_message('start_date cannot take place after end_date')
    end

    it "raises an error if the start_date and end_date aren't neighboring months" do
      start_date = '2016-12-01'.to_date
      end_date   = '2017-02-01'.to_date

      expect do
        Person
          .with_birthday_in_neighboring_months_between_two_dates(start_date, end_date)
      end.to raise_error(ArgumentError)
        .with_message('dates cannot be more than one month apart')
    end
  end
end
