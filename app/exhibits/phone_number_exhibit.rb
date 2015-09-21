class PhoneNumberExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'PhoneNumber'
  end

  def to_s
    [number, location].join(' - ')
  end

  def number
    return unless self[:number]
    phone = Phonelib.parse(self[:number])
    return unless phone.valid?
    phone_num =
        if country_code == '1' || (country_code.blank? &&
        (self[:number].length == 10 || self[:number].length == 7))

          phone.local_number
        else
          phone.e164
        end

    if phone.extension.blank?
      phone_num
    else
      "#{phone_num} ext #{phone.extension}"
    end
  end
end
