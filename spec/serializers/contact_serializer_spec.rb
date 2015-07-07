require 'spec_helper'

describe ContactSerializer do
  describe 'contacts list' do
    let(:contact) do
      c = create(:contact)
      c.addresses << build(:address)
      c
    end
    let(:person) do
      p = build(:person)
      p.email_addresses << build(:email_address)
      p.phone_numbers << build(:phone_number)
      contact.people << p
      p
    end
    let(:json) { ContactSerializer.new(contact).as_json }
    subject { json[:contact] }

    describe 'contact' do
      it { should include :id }
      it { should include :name }
      it { should include :pledge_amount }
      it { should include :pledge_frequency }
      it { should include :pledge_received }
      it { should include :status }
      it { should include :notes }
      it { should include :person_ids }
    end

    it 'people list' do
      expect(json).to include :people
    end

    it 'addresses list' do
      expect(json).to include :addresses
    end

    it 'returns frequency without trailing zeros' do
      monthly_json = ContactSerializer.new(contact).to_json
      expect(JSON.parse(monthly_json)['contact']['pledge_frequency']).to eq '1'
      contact.update_attribute(:pledge_frequency, 0.23076923076923)
      contact.reload
      weekly_json = ContactSerializer.new(contact).to_json
      expect(JSON.parse(weekly_json)['contact']['pledge_frequency']).to eq '0.23076923076923'
    end

    # it "cache_key is dependant on include params" do
    #   key = ContactSerializer.new(contact, {scope: {include: 'person'}}).cache_key
    #   expect(key).not_to eq(ContactSerializer.new(contact).cache_key)
    # end
    #
    # it "cache_key should change when updated" do
    #   expect{contact.touch}.to change { ContactSerializer.new(contact).cache_key }
    # end
  end
end
