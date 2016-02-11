require 'spec_helper'

describe Admin::ImpersonationsController do
  context '#create' do
    it 'impersonates and redirects to root if impersonation saved' do
      impersonated = create(:user_with_account)
      impersonator = create(:user_with_account)
      login(impersonator)
      impersonation = instance_double(
        Admin::Impersonation, impersonated: impersonated, save: true)
      allow(Admin::Impersonation).to receive(:new) { impersonation }
      allow(subject).to receive(:sign_in)

      post :create, reason: 'because', impersonate_lookup: 'joe to impersonate'

      expect(subject).to have_received(:sign_in).with(:user, impersonated)
      expect(response).to redirect_to(root_path)
    end

    it 'gives a flash alert and redirects to admin console if invalid' do
      login(create(:user_with_account))
      errors = double(full_messages: ['invalid'])
      impersonation = instance_double(Admin::Impersonation,
                                      save: false, errors: errors)
      allow(Admin::Impersonation).to receive(:new) { impersonation }

      post :create, reason: 'because', impersonate_lookup: 'joe to impersonate'

      expect(response).to redirect_to(admin_home_index_path)
      expect(flash[:alert]).to be_present
    end
  end
end
