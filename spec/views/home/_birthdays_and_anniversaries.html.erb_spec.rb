require 'spec_helper'

describe 'home/_birthdays_and_annviersaries.html.erb' do
  around do |example|
    travel_to Time.new(2016, 3, 1) do
      example.run
    end
  end

  it 'renders without error for invalid birthdays' do
    people = [
      build_stubbed(:person, birthday_month: 2, birthday_day: 31),
      build_stubbed(:person, birthday_month: 3, birthday_day: 31)
    ]
    account_list = double(people_with_birthdays: people,
                          contacts_with_anniversaries: [])
    locals = { current_account_list: account_list }

    expect do
      render partial: 'home/birthdays_and_anniversaries', locals: locals
    end.to_not raise_error
  end
end
