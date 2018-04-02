require 'rails_helper'

RSpec.describe ApplicationPreloader::IncludeAssociationsFetcher do
  context '#fetch_include_associations' do
    let(:association_preloader_mapping) { { contacts_that_referred_me: Api::V2::ContactsPreloader } }
    let(:resource_path) { 'Api::V2::Contacts' }
    let(:include_params) { ['contacts_that_referred_me', 'people.email_addresses'] }
    let(:field_params) { { people: 'email' } }

    subject { described_class.new(association_preloader_mapping, resource_path) }

    it 'includes all included resources and the appropriate associations for each of those' do
      expect(Api::V2::ContactsPreloader).to receive(:new).with([], field_params, 'contacts_that_referred_me')
                                                         .and_call_original
      expect_any_instance_of(Api::V2::ContactsPreloader).to receive(:associations_to_preload).and_return([])

      expect(Api::V2::Contacts::PeoplePreloader).to receive(:new).with(['email_addresses'], field_params, 'people')
                                                                 .and_call_original
      expect_any_instance_of(Api::V2::Contacts::PeoplePreloader).to receive(:associations_to_preload)
        .and_return([:email_addresses])

      result = subject.fetch_include_associations(include_params, field_params)
      expect(result).to match_array([:contacts_that_referred_me, people: [:email_addresses]])
    end
  end
end
