require 'spec_helper'

describe Admin::ImpersonationsController do
  context '#create' do
    it 'impersonates and redirects to root if impersonation saved' do
      impersonated = create(:user_with_account)
      impersonator = create(:user_with_account)
      login(impersonator)
      impersonation = instance_double(
        Admin::Impersonation, impersonated: impersonated, save: true,
                              impersonator: impersonator)
      allow(Admin::Impersonation).to receive(:new) { impersonation }

      post :create, reason: 'because', impersonate_lookup: 'joe to impersonate'

      expect(subject.current_user).to eq impersonated
      expect(response).to redirect_to(root_path)
      expect(session[:impersonator_id]).to eq impersonator.id
    end

    it 'gives a flash alert and redirects to admin console if invalid' do
      impersonator = create(:user_with_account)
      login(impersonator)
      errors = double(full_messages: ['invalid'])
      impersonation = instance_double(Admin::Impersonation,
                                      save: false, errors: errors)
      allow(Admin::Impersonation).to receive(:new) { impersonation }

      post :create, reason: 'because', impersonate_lookup: 'joe to impersonate'

      expect(response).to redirect_to(admin_home_index_path)
      expect(flash[:alert]).to be_present
      expect(subject.current_user).to eq impersonator
      expect(session[:impersonator_id]).to be_nil
    end
  end
end
