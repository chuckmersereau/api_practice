require 'rails_helper'

RSpec.describe Api::V2::Tasks::CommentsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:activity) { create(:activity, account_list: account_list) }
  let!(:resource) { create(:activity_comment, activity: activity, person: create(:person)) }
  let!(:second_resource) { create(:activity_comment, activity: activity) }
  let(:id) { resource.uuid }
  let(:parent_param) { { task_id: activity.uuid } }
  let(:parent_association) { :activity }
  let(:correct_attributes) { { body: 'My insightful comment' } }
  let(:unpermitted_attributes) { nil }
  let(:incorrect_attributes) { nil }
  let!(:not_destroyed_scope) { ActivityComment }
  let(:factory_type) { :activity_comment }

  include_examples 'show_examples'

  include_examples 'update_examples'

  context 'create examples' do
    # The ActivityComment model uses Thread.current[:user] to set it's person_id attribute
    before { Thread.current[:user] = user }
    after { Thread.current[:user] = nil }
    include_examples 'create_examples'
  end

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  describe '#index authorization' do
    it 'does not show resources for contact that user does not own' do
      api_login(user)
      activity = create(:activity, account_list: create(:user_with_account).account_lists.first)
      get :index, task_id: activity.uuid
      expect(response.status).to eq(403)
    end
  end
end
