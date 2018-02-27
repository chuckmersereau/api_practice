require 'rails_helper'

describe FacebookImport do
  let!(:user) { create(:user) }
  let!(:account) { create(:facebook_account, person_id: user.id) }
  let!(:account_list) { create(:account_list, creator: user) }
  let!(:import) do
    create(:import, source: 'facebook', source_account_id: account.id, account_list: account_list, user: user)
  end
  subject! { described_class.new(import) }

  describe 'when importing contacts' do
    let(:contact) { create(:contact, account_list: account_list) }
    let(:person) { create(:person) }
    let(:spouse) { create(:person) }

    before do
      stub_request(:get, "https://graph.facebook.com/#{account.remote_id}/friends?access_token=#{account.token}")
        .to_return(body: '{"data": [{"name": "David Hylden","id": "120581"}]}')
      stub_request(:get, "https://graph.facebook.com/120581?access_token=#{account.token}")
        .to_return(body: '{"id": "120581", "first_name": "John", "last_name": "Doe", '\
                         '"relationship_status": "Married", "significant_other":{"id":"120582"}}')
      stub_request(:get, "https://graph.facebook.com/120582?access_token=#{account.token}")
        .to_return(body: '{"id": "120582", "first_name": "Jane", "last_name": "Doe"}')
    end

    it 'should match an existing person on my list' do
      contact.people << person
      expect do
        expect(subject).to receive(:create_or_update_person).and_return(person)
        expect(subject).to receive(:create_or_update_person).and_return(create(:person)) # spouse
        subject.send(:import_contacts)
      end.to_not change(Contact, :count)
    end

    it 'should create a new contact for someone not on my list (or married to someone on my list)' do
      expect(subject).to receive(:create_or_update_person).and_return(spouse)
      expect do
        expect do
          expect(subject).to receive(:create_or_update_person).and_return(create(:person))
          subject.send(:import_contacts)
        end.to change(Person, :count).by(1)
      end.to change(Contact, :count).by(1)
    end

    it 'should match a person to their spouse if the spouse is on my list' do
      contact.people << spouse
      # spouse_account
      create(:facebook_account, person: spouse, remote_id: '120582')
      expect do
        expect do
          expect(subject).to receive(:create_or_update_person).and_return(create(:person))
          expect(subject).to receive(:create_or_update_person).and_return(spouse)
          subject.send(:import_contacts)
        end.to change(Person, :count).by(1)
      end.to_not change(Contact, :count)
    end

    it 'should add tags from the import' do
      import.update_column(:tags, 'hi, mom')
      subject.send(:import_contacts)
      expect(Contact.last.tag_list.sort).to eq(%w(hi mom))
    end
  end

  describe 'create_or_update_person' do
    let(:friend) do
      OpenStruct.new(first_name: 'John', identifier: Time.now.to_i.to_s, raw_attributes: { 'birthday' => '01/02' })
    end

    it 'should update the person if they already exist' do
      contact = create(:contact, account_list: account_list)
      person = create(:person, first_name: 'Not-John')
      create(:facebook_account, person: person, remote_id: friend.identifier)
      contact.people << person
      expect do
        subject.send(:create_or_update_person, friend, account_list)
        expect(person.reload.first_name).to eq('John')
      end.to_not change(Person, :count)
    end

    it 'should create a person with an existing Master Person if a person with this FB accoun already exists' do
      person = create(:person)
      create(:facebook_account, person: person, remote_id: friend.identifier, authenticated: true)
      expect do
        expect do
          subject.send(:create_or_update_person, friend, account_list)
        end.to change(Person, :count)
      end.to_not change(MasterPerson, :count)
    end

    it "should create a person and master peson if we can't find a match" do
      expect do
        expect do
          subject.send(:create_or_update_person, friend, account_list)
        end.to change(Person, :count)
      end.to change(MasterPerson, :count)
    end
  end
end
