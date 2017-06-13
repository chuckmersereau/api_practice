require 'rails_helper'

RSpec.describe Api::V2::AccountLists::ChalklineMailsController, type: :controller do
  let(:user)                 { create(:user_with_account) }
  let(:account_list)         { user.account_lists.first }
  let(:resource)             { AccountList::ChalklineMails.new(account_list: account_list) }
  let(:parent_param)         { { account_list_id: account_list.uuid } }
  let(:parsed_response_body) { JSON.parse(response.body) }

  describe 'POST create' do
    subject { post :create, { data: { type: 'chalkline_mails' } }.merge(parent_param) }

    context 'unauthenticated' do
      before do
        subject
      end

      it 'responds forbidden' do
        expect(response.status).to eq(401)
      end

      it 'returns a json api spec body' do
        expect(parsed_response_body).to eq('errors' => [{
                                             'status' => '401', 'title' => 'Unauthorized', 'detail' => 'Exceptions::AuthenticationError'
                                           }])
      end
    end

    context 'authenticated' do
      before do
        travel_to Time.current
        api_login(user)
        expect_any_instance_of(AccountList::ChalklineMails).to receive(:send_later).once
        subject
      end

      after { travel_back }

      it 'responds success' do
        expect(response.status).to eq(201)
      end

      it 'returns a json api spec body' do
        expect(parsed_response_body).to eq('data' => {
                                             'id' => '',
                                             'type' => 'chalkline_mails',
                                             'attributes' => { 'created_at' => Time.current.utc.iso8601, 'updated_at' => nil, 'updated_in_db_at' => nil }
                                           })
      end
    end

    context 'account list does not belong to user' do
      let(:account_list) { create(:account_list) }
      let(:expected_error_data) do
        {
          errors: [
            {
              status: '404',
              title: 'Not Found',
              detail: "Couldn't find AccountList with 'uuid'=#{account_list.uuid}"
            }
          ]
        }.deep_stringify_keys
      end

      before do
        api_login(user)
        subject
      end

      it 'responds not found' do
        expect(response.status).to eq(404)
      end

      it 'returns a json api spec body' do
        expect(parsed_response_body).to eq(expected_error_data)
      end
    end
  end
end
