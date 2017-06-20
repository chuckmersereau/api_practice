module YearCompletable
  private

  def get_four_digit_year_from_value(year_value)
    return unless year_value
    return year_value if year_value.to_s.length > 2

    "#{first_two_digits_of_year(year_value)}#{last_two_digits_of_year(year_value)}".to_i
  end

  def last_two_digits_of_year(year_value)
    return "0#{year_value}" if year_value.to_s.length == 1
    year_value
  end

  def first_two_digits_of_year(last_two_digits_of_year)
    if last_two_digits_of_current_year > last_two_digits_of_year.to_i
      first_two_digits_of_current_year
    else
      first_two_digits_of_current_year - 1
    end
  end

  def last_two_digits_of_current_year
    @last_two_digits_of_current_year ||= Date.today.year.to_s.last(2).to_i
  end

  def first_two_digits_of_current_year
    @first_two_digits_of_current_year ||= Date.today.year.to_s.first(2).to_i
  end
end
