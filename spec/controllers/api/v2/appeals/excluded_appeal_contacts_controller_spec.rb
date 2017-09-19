require 'rails_helper'

describe Api::V2::Appeals::ExcludedAppealContactsController, type: :controller do
  let(:factory_type) { :appeal_excluded_appeal_contact }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.uuid }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:excluded_appeal_contact) { create(:appeal_excluded_appeal_contact, appeal: appeal, contact: contact) }
  let!(:second_contact) { create(:contact, account_list: account_list) }
  let!(:second_excluded_appeal_contact) { create(:appeal_excluded_appeal_contact, appeal: appeal, contact: second_contact) }
  let(:id) { excluded_appeal_contact.uuid }

  let(:resource) { excluded_appeal_contact }
  let(:parent_param) { { appeal_id: appeal_id } }
  let(:correct_attributes) { {} }

  include_examples 'index_examples'
  include_examples 'show_examples'
end
