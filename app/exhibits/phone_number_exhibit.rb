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

   if country_code == '1' || (country_code.blank? && (self[:number].length == 10 || self[:number].length == 7))
      global.format
    else
      global.e164
                  end
  end

  def extension
    global = Phonelib.parse(self[:number])
    if global.extension.present?
      global.extension
    end
  end
end
