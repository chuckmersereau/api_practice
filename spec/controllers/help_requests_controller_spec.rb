require 'spec_helper'

describe HelpRequestsController do
  let(:user) { create(:user_with_account) }
  let(:valid_attributes) { { name: 'foo', email: 'foo@example.com', problem: 'bar', request_type: 'baz' } }

  before do
    sign_in(:user, user)
  end

  context '#new' do
    it 'gets form' do
      get :new
      expect(response).to be_success
    end
  end

  context '#create' do
    it 'saves a valid submission' do
      post :create, help_request: valid_attributes

      expect(response).to render_template('help_requests/thanks')
    end

    it 'shows the form again if the submission was invalid' do
      post :create, help_request: { name: '' }

      expect(response).to render_template('help_requests/new')
    end
  end

  describe 'attachment' do
    let(:hr) { create(:help_request_with_attachment) }
    context 'with matching token' do
      let(:token) { HelpRequest.attachment_token(hr.id) }
      it 'redirects when token matches' do
        get :attachment, id: token

        expect(request).to redirect_to(hr.file_url)
      end
    end

    context 'with bad token' do
      it 'renders unauthorized with bad token' do
        get :attachment, id: 'invalid_token'

        expect(response).to have_http_status(:unauthorized)

        get :attachment, id: ''

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
