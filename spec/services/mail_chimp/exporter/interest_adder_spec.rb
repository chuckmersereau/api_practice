require 'rails_helper'

RSpec.describe MailChimp::Exporter::InterestAdder do
  let(:list_id) { 'list_one' }
  let(:mail_chimp_account) { build(:mail_chimp_account) }

  let(:account_list) { mail_chimp_account.account_list }
  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }
  let(:mock_gibbon_list_object) { double(:mock_gibbon_list_object) }

  subject { described_class.new(mail_chimp_account, mock_gibbon_wrapper, list_id) }

  let(:grouping_one) do
    {
      id: 'grouping_one_id',
      title: 'Partner Status'
    }.with_indifferent_access
  end

  let(:grouping_two) do
    {
      id: 'grouping_two_id',
      title: 'Tags'
    }.with_indifferent_access
  end

  let(:mock_interest_categories) { double(:mock_interest_categories) }
  let(:mock_interests) { double(:mock_interests) }

  let(:interest_categories_create_body) { { body: { title: group_type, type: 'hidden' } } }

  before do
    allow(mock_gibbon_wrapper).to receive(:gibbon_list_object).and_return(mock_gibbon_list_object)
    allow(mock_gibbon_list_object).to receive(:interest_categories).and_return(mock_interest_categories)
    allow(mock_interest_categories).to receive(:interests).and_return(mock_interests)
  end

  context '#add_tags_interests' do
    let(:group_type) { 'Tags' }
    let(:interests_create_body) { { body: { name: 'Tag_two' } } }

    it 'creates and updates the appropriate interest_categories and adds the appropriate interests to those' do
      expect(mock_interest_categories).to receive(:retrieve).and_return(
        { 'categories' => [grouping_one] },
        'categories' => [grouping_one, grouping_two]
      )
      expect(mock_interest_categories).to receive(:create).with(interest_categories_create_body)
      expect(mock_interests).to receive(:retrieve).and_return(
        'interests' => [{ 'name' => 'Tag_one', 'id' => 'NDZA' }]
      )
      expect(mock_interests).to receive(:create).with(interests_create_body).and_return(
        'name' => 'Tag_two', 'id' => '70CFZ'
      )
      subject.add_tags_interests(%w(Tag_one Tag_two))
      expect(mail_chimp_account.tags_details[list_id][:interest_ids]).to eq(
        'Tag_one' => 'NDZA',
        'Tag_two' => '70CFZ'
      )
      expect(mail_chimp_account.tags_details[list_id][:interest_category_id]).to eq 'grouping_two_id'
    end

    it 'is fine if there are too many interests' do
      allow(mock_interest_categories).to receive(:retrieve).and_return(
        { 'categories' => [grouping_one] },
        'categories' => [grouping_one, grouping_two]
      )
      allow(mock_interest_categories).to receive(:create).with(interest_categories_create_body)
      allow(mock_interests).to receive(:retrieve).and_return(
        'interests' => [{ 'name' => 'Tag_one', 'id' => 'NDZA' }]
      )

      # create a new exception that emulates mailchimp reaching the interest limit
      exception = Gibbon::MailChimpError.new
      allow(exception).to receive(:status_code).and_return(400)
      allow(exception).to receive(:detail).and_return('Cannot have more than 2 interests per list')
      allow(mock_interests).to receive(:create).with(interests_create_body).and_raise(exception)

      expect { subject.add_tags_interests(%w(Tag_one Tag_two)) }.to_not raise_exception
    end
  end

  context '#add_status_interests' do
    let(:group_type) { 'Partner Status' }
    let(:interests_create_body) { { body: { name: 'Never Contacted' } } }

    it 'creates and updates the appropriate interest_categories and adds the appropriate interests to those' do
      expect(mock_interest_categories).to receive(:retrieve).and_return('categories' => [grouping_one])
      expect(mock_interests).to receive(:retrieve).and_return(
        'interests' => [{ 'name' => 'Partner - Pray', 'id' => '07BW' }]
      )
      expect(mock_interests).to receive(:create).with(interests_create_body).and_return(
        'name' => 'Never Contacted', 'id' => 'ABCR'
      )
      subject.add_status_interests(['Partner - Pray', 'Never Contacted'])
      expect(mail_chimp_account.statuses_details[list_id][:interest_ids]).to eq(
        'Partner - Pray' => '07BW',
        'Never Contacted' => 'ABCR'
      )
      expect(mail_chimp_account.statuses_details[list_id][:interest_category_id]).to eq 'grouping_one_id'
    end
  end
end
