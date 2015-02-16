require 'spec_helper'

describe SinglePrimaryValidator do
  let(:email_validator) { SinglePrimaryValidator.new(attributes: [:email_addresses]) }
  let(:addresses_validator) do
    SinglePrimaryValidator.new(attributes: [:addresses], primary_field: :primary_mailing_address)
  end

  it 'adds an error unless record has single primary non-historic address' do
    {
      [{ historic: false, primary_mailing_address: true }] => true,
      [] => true,
      [{ historic: true, primary_mailing_address: false }] => true,
      [{ historic: true, primary_mailing_address: true },
       { historic: true, primary_mailing_address: true }] => false,
      [{ historic: false, primary_mailing_address: true },
       { historic: false, primary_mailing_address: true }] => false,
      [{ historic: true, primary_mailing_address: true }] => false,
      [{ historic: nil, primary_mailing_address: true },
       { historic: nil, primary_mailing_address: true }] => false,
      [{ historic: nil, primary_mailing_address: false },
       { historic: nil, primary_mailing_address: false }] => false,
      [{ historic: false, primary_mailing_address: false }] => false,
      [{ historic: nil, primary_mailing_address: false, mark_for_destruction: true }] => true
    }.each do |address_attrs, valid|
      contact = build(:contact)
      contact.addresses = address_attrs.map do |attrs|
        mark_for_destruction = attrs.delete(:mark_for_destruction)
        address = build(:address, attrs)
        address.mark_for_destruction if mark_for_destruction
        address
      end
      addresses_validator.validate(contact)
      expect(contact.errors.empty?).to eq(valid)
    end
  end

  it 'correctly uses :primary as the default primary_field' do
    {
      [{ historic: false, primary: true }] => true,
      [{ historic: false, primary: false }] => false
    }.each do |email_attrs, valid|
      person = build(:person, email_addresses: email_attrs.map { |attrs| build(:email_address, attrs) })
      email_validator.validate(person)
      expect(person.errors.empty?).to eq(valid)
    end
  end
end
