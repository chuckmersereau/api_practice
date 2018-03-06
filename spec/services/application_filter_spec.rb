require 'rails_helper'

describe ApplicationFilter do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  describe '#query' do
    let(:contact_one) { create(:contact, name: 'name') }
    let(:contact_two) { create(:contact, name: 'not name') }

    describe '#without reverse flag' do
      let(:filter) { { simple_name_search: 'name' } }

      it 'returns the resources after filtering' do
        expect(SimpleNameSearch.new(account_list).query(Contact, filter)).to eq [contact_one]
      end
    end

    describe '#with reverse flag' do
      let(:filter) { { simple_name_search: 'name', reverse_simple_name_search: true } }

      it 'returns the revese of resources that would be returned by filtering' do
        expect(SimpleNameSearch.new(account_list).query(Contact, filter)).to eq [contact_two]
      end
    end

    class SimpleNameSearch < ApplicationFilter
      def execute_query(scope, filters)
        scope.where(name: filters[:simple_name_search])
      end
    end
  end
end
