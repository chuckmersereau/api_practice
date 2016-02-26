require 'spec_helper'

describe Admin::AccountDupPhonesFix, '#fix' do
  it 'does a dup phone number fix for every person with multiple numbers' do
    account_list = create(:account_list)
    contact = create(:contact, account_list: account_list)
    person_1_phone = create(:person)
    person_1_phone.add_phone_number(number: '123-45-6789')
    person_1_phone.save
    person_2_phones = create(:person)
    person_2_phones.add_phone_number(number: '123-45-6789')
    person_2_phones.add_phone_number(number: '223-45-6789')
    person_2_phones.save
    contact.people << [person_1_phone, person_2_phones]
    allow(Admin::DupPhonesFix).to receive(:new) { double(fix: nil) }

    Admin::AccountDupPhonesFix.new(account_list).fix

    expect(Admin::DupPhonesFix).to have_received(:new) do |person|
      expect(person).to eq person_2_phones
    end
  end
end
