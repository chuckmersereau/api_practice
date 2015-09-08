class PhoneNumberExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'PhoneNumber'
  end

  def to_s
    [number, location].join('')
  end

  def number
    return unless self[:number]

    global = Phonelib.parse(self[:number])
    return unless global

    number = if country_code == '1' || (country_code.blank? && (self[:number].length == 10 || self[:number].length == 7))
      global.national
    else
      global.international
             end
  end

  def extension
    :number[12..15]
  end
end
