require 'rails_helper'

RSpec.describe MailChimp::Exporter::MergeFieldAdder do
  let(:list_id) { 'list_one' }
  let(:mail_chimp_account) { build(:mail_chimp_account) }

  let(:account_list) { mail_chimp_account.account_list }
  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }
  let(:mock_gibbon_list_object) { double(:mock_gibbon_list_object) }

  subject { described_class.new(mail_chimp_account, mock_gibbon_wrapper, list_id) }

  let(:mock_merge_fields) { double(:mock_merge_fields) }

  let(:merge_field_create_body) do
    {
      body: {
        tag: 'RANDOM_FIELD',
        name: 'Random_field',
        type: 'text'
      }
    }
  end

  before do
    allow(mock_gibbon_wrapper).to receive(:gibbon_list_object).and_return(mock_gibbon_list_object)
    allow(mock_gibbon_list_object).to receive(:merge_fields).and_return(mock_merge_fields)
  end

  context '#add_merge_field' do
    let(:group_type) { 'Tags' }
    let(:interests_create_body) { { body: { name: 'Tag_two' } } }

    it 'creates and updates the appropriate tag group names and adds the appropriate groups to those' do
      expect(mock_merge_fields).to receive(:retrieve).and_return('merge_fields' => [{ 'tag' => 'field_one' }])
      expect(mock_merge_fields).to receive(:create).with(merge_field_create_body)
      subject.add_merge_field('RANDOM_FIELD')
    end
  end
end
