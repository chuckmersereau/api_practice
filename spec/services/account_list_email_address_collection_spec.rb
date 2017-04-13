require 'rails_helper'

RSpec.describe AccountListEmailCollection, type: :service do
  describe '#initialize' do
    it 'initializes with an account_list' do
      account_list = double('account_list')
      collection = AccountListEmailCollection.new(account_list)

      expect(collection.account_list).to eq account_list
    end
  end

  describe '#data' do
    let(:account_list) { create(:account_list) }
    let(:contact)      { create(:contact, account_list_id: account_list.id) }
    let(:person)       { create(:person).tap { |person| contact.people << person } }
    let(:email)        { create(:email_address).tap { |email| person.email_addresses << email } }

    it 'returns related data for the account list & emails associated with it' do
      expected_data = [
        [contact.id, person.id, email.email]
      ]

      collection = AccountListEmailCollection.new(account_list)

      expect(collection.data).to eq expected_data
    end
  end

  describe '#emails' do
    it 'returns a sorted list of all emails associated with the account_list' do
      account_list = double('account_list')

      data = [
        [123, 456, 'sam@example.com'],
        [123, 567, 'pippin@example.com'],
        [123, 987, 'SAM@EXAMPLE.com']
      ]

      expected_emails = [
        'pippin@example.com',
        'sam@example.com'
      ]

      collection = AccountListEmailCollection.new(account_list)

      allow(collection)
        .to receive(:data)
        .and_return(data)

      expect(collection.emails).to eq expected_emails
    end
  end

  describe '#indexed_data' do
    it 'converts the found data to a hash with normalized emails as keys' do
      account_list = double('account_list')

      data = [
        [123, 456, 'sam@example.com'],
        [123, 567, 'pippin@example.com'],
        [123, 987, 'SAM@EXAMPLE.com']
      ]

      expected_indexed_data = {
        'sam@example.com' => [
          { contact_id: 123, person_id: 456, email: 'sam@example.com' },
          { contact_id: 123, person_id: 987, email: 'SAM@EXAMPLE.com' }
        ],
        'pippin@example.com' => [
          { contact_id: 123, person_id: 567, email: 'pippin@example.com' }
        ]
      }

      collection = AccountListEmailCollection.new(account_list)

      allow(collection)
        .to receive(:data)
        .and_return(data)

      expect(collection.indexed_data).to eq expected_indexed_data
    end
  end

  describe '#includes?' do
    it 'takes in an object' do
    end
  end
end
