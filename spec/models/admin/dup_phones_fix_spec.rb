require 'spec_helper'

describe Admin::DupPhonesFix, '#fix' do
  it 'combines dup phone numbers' do
    person = build_person(
      { number: '617-456-7890', primary: true },
      { number: '+16174567890' },
      { number: '+617-456-7890' },
      { number: '220-456-7890' },
      { number: '+633111111' },
      number: '617-456-7890'
    )

    Admin::DupPhonesFix.new(person).fix

    numbers = person.reload.phone_numbers.to_a.sort
    expect(numbers.map(&:number))
      .to eq ['+16174567890', '+12204567890', '+633111111']
    expect(numbers[0]).to be_primary
    expect(numbers[1]).to_not be_primary
    expect(numbers[2]).to_not be_primary
  end

  def build_person(*numbers_attrs)
    person = create(:person)
    numbers_attrs.each do |attrs|
      phone = create(:phone_number, person: person, primary: attrs[:primary])
      # Calling update_column is needed to get around the auto-normalization of
      # the current phone number code (we are simulating old non-normalized numbers)
      phone.update_column(:number, attrs[:number])
    end
    person
  end
end
