require 'rails_helper'

RSpec.describe Api::V2::BackgroundBatchesController, type: :controller do
  let(:user)             { create(:user_with_account) }
  let(:account_list)     { user.account_lists.first }
  let(:factory_type)     { :background_batch }
  let!(:resource)        { create(:background_batch, user: user) }
  let!(:second_resource) { create(:background_batch, user: user) }
  let(:id)               { resource.uuid }
  let(:correct_attributes)   { {} }
  let(:incorrect_attributes) { nil }
  let(:correct_relationships) do
    {
      requests: {
        data: [
          {
            type: 'background_batch_requests',
            id: SecureRandom.uuid,
            attributes: {
              path: 'api/v2/user'
            }
          }
        ]
      }
    }
  end

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
