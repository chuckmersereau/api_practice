require 'spec_helper'

describe PhoneNumber do
  describe 'adding a phone number to a person' do
    before(:each) do
      @person = FactoryGirl.create(:person)
      @attributes = { 'number' => '213-345-2313' }
    end
    it "creates a phone number if it's new" do
      expect do
        PhoneNumber.add_for_person(@person, @attributes)
        phone_number = @person.reload.phone_numbers.first
        expect(phone_number.number).to eq('+12133452313')
      end.to change(PhoneNumber, :count).from(0).to(1)
    end

    it "doesn't create a phone number if it exists" do
      PhoneNumber.add_for_person(@person, @attributes)
      expect do
        PhoneNumber.add_for_person(@person, @attributes)
        expect(@person.phone_numbers.first.number).to eq('+12133452313')
      end.to_not change(PhoneNumber, :count)
    end

    it 'sets only the first phone number to primary' do
      PhoneNumber.add_for_person(@person, @attributes)
      expect(@person.phone_numbers.first.primary?).to eq(true)
      PhoneNumber.add_for_person(@person, @attributes.merge('number' => '313-313-3142'))
      expect(@person.phone_numbers.last.primary?).to eq(false)
    end

    it 'sets a prior phone number to not-primary if the new one is primary' do
      phone1 = PhoneNumber.add_for_person(@person, @attributes)
      expect(phone1.primary?).to eq(true)

      phone2 = PhoneNumber.add_for_person(@person,  number: '313-313-3142', primary: true)
      expect(phone2.primary?).to eq(true)
      phone2.send(:ensure_only_one_primary)
      expect(phone1.reload.primary?).to eq(false)
    end
  end

  describe 'clean_up_number' do
    it 'should parse out the country code' do
      pn = PhoneNumber.new(number: '+44 12345532')
      pn.clean_up_number
      expect(pn.country_code).to eq('44')
    end

    it 'returns a number and extension when provided' do
      phone = PhoneNumber.new(number: '213-345-2313;23')
      phone.clean_up_number
      expect(phone.number).to eq('+12133452313;23')
    end
  end

  # it 'should format a US number based on country code' do
  # p = PhoneNumber.new(number: '1567890', country_code: '1')
  # expect(p.to_s).to eq('156-7890')
  # end
  # it 'should format a US number based on length' do
  # p = PhoneNumber.new(number: '1234567890', country_code: nil)
  # expect(p.to_s).to eq('(123) 456-7890')
  # end
  # it 'should leave all other countries alone' do
  # p = PhoneNumber.new(number: '1234567890', country_code: '999999999')
  # expect(p.to_s).to eq('1234567890')
  # end
end
