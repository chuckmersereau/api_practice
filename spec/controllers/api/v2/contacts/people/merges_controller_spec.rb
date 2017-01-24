require 'spec_helper'

RSpec.describe Api::V2::Contacts::People::MergesController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  # This MAY be required!
  let(:account_list) { user.account_lists.first }

  # This is required!
  let(:factory_type) do
    :person
  end

  let!(:contact) { create(:contact, name: 'Doe, John', account_list: account_list) }
  let!(:winner) { create(:person, first_name: 'John', last_name: 'Doe') }
  let!(:loser) { create(:person, first_name: 'John', last_name: 'Doe 2') }

  before do
    contact.people << winner
    contact.people << loser
    create(:email_address, person: resource) # Test inclusion of related resources.
  end

  # This is required!
  let!(:resource) do
    winner
  end

  let(:parent_param) do
    { contact_id: contact.uuid }
  end

  # This is required!
  let(:correct_attributes) do
    { winner_id: winner.uuid, loser_id: loser.uuid }
  end

  # This is required!
  let(:unpermitted_attributes) do
    nil
  end

  # This is required!
  let(:incorrect_attributes) do
    { winner_id: nil, loser_id: nil }
  end

  include_context 'common_variables'

  describe '#create' do
    include_examples 'including related resources examples',
                     action: :create,
                     expected_response_code: 200

    include_examples 'sparse fieldsets examples',
                     action: :create,
                     expected_response_code: 200

    it 'merges the two contacts for users that are signed in' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
      end.to change(&count_proc).by(-1)
      expect(response.status).to eq(200)
    end

    it 'does not perform the merge when there are unpermitted params' do
      if unpermitted_attributes
        api_login(user)
        expect do
          post :create, full_unpermitted_attributes
        end.not_to change(&count_proc)
        expect(response.status).to be_between(400, 499)
        expect(response_errors).to be_present
      end
    end

    it 'does not perform the merge when there are errors in sent data' do
      if incorrect_attributes
        api_login(user)

        expect do
          post :create, full_incorrect_attributes
        end.not_to change(&count_proc)

        expect(response.status).to be_between(400, 499)
        expect(response.body).to include('errors')
      end
    end

    it 'does not perform the merge for users that are not signed in' do
      expect do
        post :create, full_correct_attributes
      end.not_to change(&count_proc)

      expect(response.status).to eq(401)
      expect(response_errors).to be_present
    end
  end
end
