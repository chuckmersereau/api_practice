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
    expect_numbers_merged(['+6174567890', '+16174567890'], 
                          ['+16174567890'])
  end

  it 'leaves non-dup international numbers that look US number missing +1' do
    expect_numbers_merged(['+4412345678', '+6431234567'],
                          ['+4412345678', '+6431234567'])
  end

  def expect_numbers_merged(unmerged, merged)
    person = build_person(*unmerged.map { |n| { number: n } })

    Admin::DupPhonesFix.new(person).fix

    expect(person.reload.phone_numbers.pluck(:number)).to eq merged
  end

  def build_person(*numbers_attrs)
    person = create(:person)
    numbers_attrs.each do |attrs|
      phone = create(:phone_number, attrs.merge(person: person))
      # Calling update_column is needed to get around the auto-normalization of
      # the current phone number code (we are simulating old non-normalized numbers)
      phone.update_column(:number, attrs[:number])
    end
    person
  end
end
