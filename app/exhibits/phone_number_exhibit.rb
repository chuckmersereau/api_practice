class PhoneNumberExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'PhoneNumber'
  end

  def to_s
    [number, location].join('')
  end

  def number
    return unless self[:number]
    phone = Phonelib.parse(self[:number])
    return unless phone.valid?

    if country_code == '1' || (country_code.blank? && (self[:number].length == 10 || self[:number].length == 7))
      phone.national.gsub(/(\d{3})(\d{3})(\d{4})/, '(\\1) \\2-\\3')
    else
      phone.e164
    end
  end

  def extension
    phone = Phonelib.parse(self[:number])
    phone.extension if phone.extension.present?
  end
end
