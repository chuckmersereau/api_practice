require 'spec_helper'

describe Api::V1::ContactsController do
  describe 'api' do
    let(:user) { create(:user_with_account) }
    let!(:contact) { create(:contact, account_list: user.account_lists.first, pledge_amount: 100) }

    context '#count' do
      it 'succeeds' do
        get :count, access_token: user.access_token
        expect(response).to be_success
      end
    end

    context '#tags' do
      it 'succeeds' do
        contact.tag_list << 'test tag'
        contact.save!

        get :tags, access_token: user.access_token
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json['tags'].length).to eq(1)
      end
    end

    context '#index' do
      it 'filters address out' do
        get :index, access_token: user.access_token, include: 'Contact.name,Contact.id,Contact.avatar'
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json).not_to include 'address'
        expect(json).to include 'contacts'
        expect(json['contacts'][0]).to include 'id'
        expect(json['contacts'][0]).to include 'avatar'
        expect(json['contacts'][0]).not_to include 'pledge_amount'
      end
    end
  end
end
