require 'rails_helper'

RSpec.describe ApplicationPreloader do
  context 'methods' do
    let(:include_params) { ['addresses', 'primary_person', 'people.facebook_accounts'] }
    let(:field_params) do
      {
        addresses: ['region'],
        contacts: ['name'],
        facebook_accounts: ['remote_id'],
        primary_person: %w(first_name avatar email)
      }
    end
    let!(:contact_one) { create(:contact) }
    let!(:contact_two) { create(:contact) }
    let!(:person_one) { create(:person, contacts: [contact_one]) }
    let!(:person_two) { create(:person, contacts: [contact_two]) }
    let!(:contacts) { Contact.all }

    let(:expected_associations) do
      [
        :addresses,
        :primary_person,
        { primary_person: [:primary_picture, :primary_email_address] },
        { people: [:facebook_accounts] }
      ]
    end

    subject { ContactsPreloader.new(include_params, field_params) }

    describe '#preload' do
      it 'preloads the correct association' do
        expect(contacts).to receive(:preload).with(*expected_associations)
        subject.preload(contacts)
      end
    end

    describe '#associations_to_preload' do
      describe 'if specific associations are included' do
        it 'preloads the correct association' do
          expect(subject.associations_to_preload).to eq(expected_associations)
        end
      end
    end

    module Contacts
      class AddressesPreloader < ApplicationPreloader
        ASSOCIATION_PRELOADER_MAPPING = {}.freeze
        FIELD_ASSOCIATION_MAPPING = {}.freeze
      end

      class PeoplePreloader < ApplicationPreloader
        ASSOCIATION_PRELOADER_MAPPING = {}.freeze
        FIELD_ASSOCIATION_MAPPING = { avatar: :primary_picture, email: :primary_email_address }.freeze
      end

      module People
        class FacebookAccountsPreloader < ApplicationPreloader
          ASSOCIATION_PRELOADER_MAPPING = {}.freeze
          FIELD_ASSOCIATION_MAPPING = {}.freeze

          def serializer_class
            Person::FacebookAccountSerializer
          end
        end
      end
    end

    class ContactsPreloader < ApplicationPreloader
      ASSOCIATION_PRELOADER_MAPPING = { primary_person: Contacts::PeoplePreloader }.freeze
      FIELD_ASSOCIATION_MAPPING = {}.freeze
    end
  end
end
