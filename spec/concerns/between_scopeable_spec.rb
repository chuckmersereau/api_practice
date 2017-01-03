require 'spec_helper'

RSpec.describe BetweenScopeable, type: :concern do
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

  let(:results) do
    Person.with_birthday_between(christmas_day_2016, st_patricks_day_2017)
  end

  it 'adds a scope for finding records between two dates' do
    expect(results).to include person_with_birthday_on_new_years_eve
    expect(results).to include person_with_birthday_on_valentines

    expect(results).not_to include person_with_birthday_on_christmas_eve
    expect(results).not_to include person_with_birthday_on_fathers_day
  end
end
