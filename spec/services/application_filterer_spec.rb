require 'rails_helper'

describe ApplicationFilterer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  describe '.config' do
    it 'returns an empty array' do
      expect(described_class.config([account_list])).to eq []
    end
  end

  describe '.filter_classes' do
    it 'returns an empty array' do
      expect(described_class.filter_classes).to eq []
    end
  end

  describe '.filter_params' do
    it 'returns an empty array' do
      expect(described_class.filter_params).to eq []
    end
  end

  describe '#initialize' do
    it 'initializes filters variable' do
      expect(described_class.new(abc: '123').filters).to eq('abc' => '123')
    end

    it 'intializes filters with_indifferent_access' do
      expect(described_class.new(abc: { 'def' => '123' }).filters[:abc][:def]).to eq('123')
    end

    it 'strips filter string params' do
      expect(described_class.new(abc: ' 1 2 3 ').filters).to eq('abc' => '1 2 3')
    end
  end

  describe '#filter' do
    it 'returns the resource scope' do
      resource_scope = Contact.all
      expect(described_class.new.filter(scope: resource_scope, account_lists: [account_list])).to eq resource_scope
    end
  end

  describe '#with any_filter flag' do
    let(:account_list) { create(:account_list) }

    let!(:contact_one) { create(:contact, account_list: account_list) }
    let!(:contact_two) { create(:contact, account_list: account_list, name: 'name') }
    let!(:contact_three) { create(:contact, account_list: account_list) }

    let(:filters) { { simple_name_search: 'name', simple_date_search: contact_one.created_at, any_filter: true } }

    it 'returns results that apply to any filter' do
      expect(Contact::ContactFilterer.new(filters).filter(scope: account_list.contacts, account_lists: [account_list])).to eq [contact_one, contact_two]
    end

    class Contact::ContactFilterer < ApplicationFilterer
      FILTERS_TO_HIDE = %w(SimpleNameSearch SimpleDateSearch).freeze
    end

    module Contact::Filter
      class SimpleNameSearch < ApplicationFilter
        def execute_query(scope, filters)
          scope.where(name: filters[:simple_name_search])
        end
      end

      class SimpleDateSearch < ApplicationFilter
        def execute_query(scope, filters)
          scope.where(created_at: filters[:simple_date_search])
        end
      end
    end
  end
end
