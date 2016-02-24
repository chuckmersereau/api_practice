class Admin::DupPhonesFix
  def initialize(person)
    @person = person
  end

  def fix
    phones.each(&method(:normalize))
    phones.group_by(&:number).each(&method(:merge_dup_phones))
  end

  private

  attr_reader :person

  def phones
    @phones ||= person.phone_numbers.order(:created_at).to_a
  end

  def normalize(phone)
    fix_missing_us_country_prefix(phone)
    phone.clean_up_number
    phone.save
  end

  def fix_missing_us_country_prefix(phone)
    # Sometimes (in past or present code), a US phone number can get saved
    # without the +1 but with a +, i.e. +6171234567 instead of +1617234567.
    # Some US area codes are actually country codes so in principle the number
    # could be ambiguous, but if the country code is 1 and the number has 10
    # digits (9 digits after the + and initial digit of 2-9), then it's a
    # resonable assumption that this really is a US phone number, so add the
    # missing 1 after the +. I've seen duplicated numbers based on this
    # normalization in user data, so this will help make the de-duping more
    # complete.
    return unless phone.number =~ /\A\+[2-9]\d{9}/ && phone.country_code == '1'
    phone.number = "+1#{phone.number[1..-1]}"
  end

  def merge_dup_phones(_number, phones)
    return unless phones.size > 1
    first_phone = phones[0]
    phones[1..-1].each { |phone| first_phone.merge(phone) }
  end
end
