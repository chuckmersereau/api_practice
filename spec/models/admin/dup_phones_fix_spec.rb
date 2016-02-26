require 'spec_helper'

describe Admin::DupPhonesFix, '#fix' do
  it 'combines dup numbers and keeps primary one the same' do
    person = build_person(
      { number: '617-456-7890', primary: true },
      { number: '+16174567890' },
      number: '220-456-7890'
    )

    Admin::DupPhonesFix.new(person).fix

    numbers = person.reload.phone_numbers.to_a.sort
    expect(numbers.map(&:number)).to eq ['+16174567890', '+12204567890']
    expect(numbers[0]).to be_primary
    expect(numbers[1]).to_not be_primary
  end

  it 'combines dup US phone numbers that differ by missing 1 after +' do
    expect_fix_result(
      [{ number: '+6042345678', country_code: '60' }, { number: '+16042345678' }],
      ['+16042345678'])
  end

  it 'leaves alone non-dup int numbers that look US number missing +1' do
    expect_fix_result(
      [{ number: '+4412345678', country_code: '1' },
       { number: '+6431234567', country_code: '64' }],
      ['+4412345678', '+6431234567'])
  end

  def expect_fix_result(unfixed_numbers_attrs, fixed_numbers)
    person = build_person(*unfixed_numbers_attrs)

    Admin::DupPhonesFix.new(person).fix

    expect(person.reload.phone_numbers.pluck(:number)).to eq fixed_numbers
  end

  def build_person(*numbers_attrs)
    person = create(:person)
    numbers_attrs.each do |attrs|
      phone = create(:phone_number, attrs.merge(person: person))
      # Calling update_column is needed to get around the auto-normalization of
      # the current phone number code (we are simulating old non-normalized numbers)
      phone.update_column(:number, attrs[:number])
      phone.update_column(:country_code, attrs[:country_code]) if attrs[:country_code]
    end
    person
  end
end
