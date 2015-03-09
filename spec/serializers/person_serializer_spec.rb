require 'spec_helper'

describe PersonSerializer do
  let(:person) do
    p = build(:person)
    p.email_addresses << build(:email_address)
    p.phone_numbers << build(:phone_number)
    p
  end
  subject { PersonSerializer.new(person).as_json }

  it { should include :email_addresses }
  it { should include :phone_numbers }
end
