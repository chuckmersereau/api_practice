RSpec.shared_examples 'destroy_examples' do |_options = {}|
  include_context 'common_variables'

  describe '#destroy' do
    it 'destroys resource object to users that are signed in' do
      api_login(user)
      expect do
        delete :destroy, full_params
      end.to change(&count_proc).by(-1)
      expect(response.status).to eq(204)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        expect do
          delete :destroy, full_params
        end.not_to change(&count_proc)
        expect(response.status).to eq(403)
      end
    end

    it 'does not destroy resource object to users that are signed in' do
      expect do
        delete :destroy, full_params
      end.not_to change(&count_proc)
      expect(response.status).to eq(401)
    end
  end
end
