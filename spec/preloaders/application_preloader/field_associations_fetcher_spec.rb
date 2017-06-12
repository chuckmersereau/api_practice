require 'rails_helper'

RSpec.describe ApplicationPreloader::FieldAssociationsFetcher do
  context '#fetch_field_associations' do
    let(:field_params) { %w(first_name avatar) }
    let(:field_association_mapping) { { avatar: :primary_picture, email: :primary_email_address } }
    let(:serializer_class) { MockPersonSerializer }

    subject { described_class.new(field_association_mapping, serializer_class) }

    it 'returns all associations if no field_params is provided' do
      expect(subject.fetch_field_associations(nil)).to match_array(
        [:email_addresses, :primary_email_address, :primary_picture]
      )
    end

    it 'returns required associations when field_params are provided' do
      expect(subject.fetch_field_associations(field_params)).to eq(
        [:primary_picture]
      )
    end

    class MockPersonSerializer < ApplicationSerializer
      belongs_to :email_addresses
    end
  end
end
