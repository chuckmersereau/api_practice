class Admin::DupPhonesFix
  def initialize(person)
    @person = person
  end

  def fix
    phones.each(&method(:normalize))
    phones.each(&method(:fix_missing_us_country_prefix))
    phones.group_by(&:number).each(&method(:merge_dup_phones))
  end

  private

  attr_reader :person

  def phones
    @phones ||= person.phone_numbers.order(:created_at).to_a
  end

  def normalize(phone)
    phone.clean_up_number
    phone.save
  end

  def fix_missing_us_country_prefix(phone)
    # Sometimes (in past or present code), a US phone number got saved
    # without the +1 but with a +, i.e. +6171234567 instead of +1617234567.
    return unless phone.number =~ /\A\+[2-9]\d{9}/ && phone.country_code == '1'

    us_country_code_added = "+1#{phone.number[1..-1]}"

    # Sometimes a 10-digit number with a + in front could actually be an
    # international number, so only make the assumption that this number is
    # actually a US number with a missing country code if there is another phone
    # for that person where the country code is not missing.
    return unless phones.any? { |p| p.number == us_country_code_added }

    phone.update(number: us_country_code_added)
  end

  def merge_dup_phones(_number, phones)
    return unless phones.size > 1
    first_phone = phones[0]
    phones[1..-1].each { |phone| first_phone.merge(phone) }
  end
end
