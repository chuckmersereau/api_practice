require 'spec_helper'
describe PhoneNumberExhibit do
  subject { PhoneNumberExhibit.new(phone_number, context) }
  let(:phone_number) { build(:phone_number, number: '2134567890', country_code: '1') }
  let(:context) { double }

  it 'returns a formatted number' do
    allow(context).to receive(:number_to_phone).and_return('(213) 456-7890')
    expect(subject.number).to eq('(213) 456-7890')
  end

  it "should return nil number if it's not a valid phone number" do
    phone_number.number = '555'
    phone_number.country_code = '2'
    expect(subject.number).to be_nil
  end

  it 'should return an extension when included in the number' do
    phone_number.number = '2135555555;ext=1234'
    expect(subject.number).to eq('(213) 555-5555 ext 1234')
  end
end
