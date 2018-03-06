require 'rails_helper'

describe Person::Filterer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  describe '.config' do
    it 'returns an empty array' do
      expect(described_class.config([account_list])).to eq []
    end
  end

  describe '.filter_classes' do
    it 'returns an empty array' do
      expect(described_class.filter_classes).to eq [Person::Filter::Deceased,
                                                    Person::Filter::EmailAddressValid,
                                                    Person::Filter::PhoneNumberValid,
                                                    Person::Filter::UpdatedAt,
                                                    Person::Filter::WildcardSearch]
    end
  end

  describe '.filter_params' do
    it 'returns an empty array' do
      expect(described_class.filter_params).to eq [:deceased, :email_address_valid, :phone_number_valid, :updated_at, :wildcard_search]
    end
  end

  describe '#filter' do
    it 'returns the resource scope' do
      resource_scope = Person.all
      expect(described_class.new.filter(scope: resource_scope, account_lists: [account_list])).to eq resource_scope
    end
  end
end
