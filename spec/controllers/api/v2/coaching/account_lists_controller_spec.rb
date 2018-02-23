require 'rails_helper'

describe Api::V2::Coaching::AccountListsController, type: :controller do
  let(:resource_type) { 'account_lists' }
  let(:factory_type) { :account_list }
  let!(:user) { create(:user, locale: :en) }
  let!(:owner) { create(:user_with_account) }

  let!(:coaches) { create_list(:user_coach, 2) }
  let!(:account_list) { owner.account_lists.order(:created_at).first }
  let!(:account_list_2) { create(:account_list, created_at: 1.week.from_now) }
  let(:account_list_id) { account_list.id }
  let(:id) { account_list.id }

  before do
    [account_list, account_list_2].each do |list|
      list.coaches += coaches
      list.coaches << user.becomes(User::Coach)
    end
  end

  let(:resource) { account_list }
  let(:correct_attributes) { attributes_for(:account_list) }

  include_examples 'index_examples'
  include_examples 'show_examples'
end
