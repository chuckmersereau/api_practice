require 'spec_helper'

RSpec.describe Api::V2::Contacts::MergesController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  # This MAY be required!
  let(:account_list) { user.account_lists.first }

  # This is required!
  let(:factory_type) do
    :contact
  end

  let!(:winner) { create(:contact, name: 'Doe, John', account_list: account_list) }
  let!(:loser) { create(:contact, name: 'Doe, John 2', account_list: account_list) }
  let!(:non_owned_contact) { create(:contact, name: 'Doe, Jane 1') }

  # This is required!
  let!(:resource) { winner }

  # This is required!
  let(:correct_attributes) do
    { winner_id: winner.uuid, loser_id: loser.uuid }
  end

  # This is required!
  let(:unpermitted_attributes) do
    { winner_id: non_owned_contact.uuid, loser_id: loser.uuid }
  end

  # This is required!
  let(:incorrect_attributes) do
    { winner_id: nil, loser_id: nil }
  end

  # These includes can be found in:
  # spec/support/shared_controller_examples.rb
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
