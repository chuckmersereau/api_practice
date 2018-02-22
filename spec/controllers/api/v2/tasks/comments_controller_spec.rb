require 'rails_helper'

RSpec.describe Api::V2::Tasks::CommentsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:person) { create(:contact_with_person, account_list: account_list).reload.people.first }
  let(:activity) { create(:activity, account_list: account_list) }
  let!(:resource) { create(:activity_comment, activity: activity, person: user) }
  let!(:second_resource) { create(:activity_comment, activity: activity, person: person) }
  let(:id) { resource.id }
  let(:parent_param) { { task_id: activity.id } }
  let(:parent_association) { :activity }
  let(:correct_attributes) { { body: 'My insightful comment' } }
  let(:unpermitted_attributes) { nil }
  let(:incorrect_attributes) { nil }
  let!(:not_destroyed_scope) { ActivityComment }
  let(:factory_type) { :activity_comment }
  let(:correct_relationships) do
    {
      person: {
        data: {
          type: 'people',
          id: user.id
        }
      }
    }
  end
  let(:unpermitted_relationships) do
    {
      person: {
        data: {
          type: 'people',
          id: create(:person).id
        }
      }
    }
  end

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  describe '#index authorization' do
    it 'does not show resources for contact that user does not own' do
      api_login(user)
      activity = create(:activity, account_list: create(:user_with_account).account_lists.order(:created_at).first)
      get :index, task_id: activity.id
      expect(response.status).to eq(403)
    end
  end
end
