require 'rails_helper'

RSpec.describe Api::V2::Contacts::DuplicatesController, type: :controller do
  let(:factory_type) { :duplicate_contacts_pair }

  let!(:duplicate_record_pair) { create(:duplicate_contacts_pair) }
  let!(:second_duplicate_record_pair) { create(:duplicate_contacts_pair, account_list: duplicate_record_pair.account_list) }

  let(:account_list) { duplicate_record_pair.account_list }
  let(:user) { create(:user).tap { |user| account_list.users << user } }

  let(:resource) { duplicate_record_pair }
  let(:second_resource) { second_duplicate_record_pair }

  let(:id) { duplicate_record_pair.id }

  let(:correct_attributes) do
    {
      reason: 'Testing',
      updated_in_db_at: resource.updated_at
    }
  end

  let(:correct_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.id
        }
      },
      records: {
        data: [
          {
            type: 'contact',
            id: account_list.contacts.first.id
          },
          {
            type: 'contact',
            id: account_list.contacts.second.id
          }
        ]
      }
    }
  end

  let(:unpermitted_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: create(:account_list).id
        }
      }
    }
  end

  let(:reference_key) { :reason }
  let(:reference_value) { correct_attributes[:reason] }
  let(:incorrect_reference_value) { resource.send(reference_key) }

  let(:incorrect_attributes) do
    {
      reason: nil,
      updated_in_db_at: resource.updated_at
    }
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'
end
