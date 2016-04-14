require 'spec_helper'

describe Admin::OfflineOrgController do
  context '#create' do
    it 'creates a new offline org and redirects to admin home' do
      login(create(:admin_user))
      expect do
        post :create, name: 'new org', website: 'new.example.com', organization: { country: 'United Kingdom' }
      end.to change(Organization, :count).by(1)
      org = Organization.last
      expect(org.name).to eq 'new org'
      expect(org.org_help_url).to eq 'new.example.com'
      expect(org.country).to eq 'United Kingdom'
      expect(response).to redirect_to admin_home_index_path
      expect(flash[:notice]).to be_present
    end
  end
end
