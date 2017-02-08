require 'rails_helper'

RSpec.describe ErrorSerializer, type: :serializer do
  let(:resource) { MockResource.new }
  let(:title)    { 'Not Found' }
  let(:detail)   { "Couldn't find resource at /api/v2/google" }
  let(:status)   { 400 }

  let(:error_hash) do
    {
      name: "can't be blank",
      email: 'must be unique'
    }
  end

  describe '#initialize' do
    it 'must initialize with a status' do
      expect { ErrorSerializer.new(status: nil) }.to raise_error ArgumentError
    end

    it 'must initialize with either a title or a resource or a hash' do
      invalid_args = {
        status: status,
        hash: nil,
        resource: nil,
        title: nil
      }

      expect { ErrorSerializer.new(invalid_args) }
        .to raise_error ArgumentError

      expect { ErrorSerializer.new(resource: resource, status: status) }
        .not_to raise_error

      expect { ErrorSerializer.new(title: title, status: status) }
        .not_to raise_error

      expect { ErrorSerializer.new(hash: error_hash, status: status) }
        .not_to raise_error
    end
  end

  describe '#as_json' do
    it 'returns a Hash' do
      serializer = ErrorSerializer.new(status: 400, resource: resource)
      expect(serializer.as_json).to be_a Hash
    end

    context 'with a resource' do
      it 'will correctly generate the json for the errors on the resource' do
        expected_json_hash = {
          errors: [
            {
              status: 400,
              source: { pointer: '/data/attributes/name' },
              title: 'must be in ALL CAPS',
              detail: 'Name must be in ALL CAPS'
            },
            {
              status: 400,
              source: { pointer: '/data/attributes/name' },
              title: 'must contain a ?',
              detail: 'Name must contain a ?'
            },
            {
              status: 400,
              source: { pointer: '/data/attributes/email' },
              title: 'has already been taken',
              detail: 'Email has already been taken'
            }
          ]
        }.as_json

        serializer = ErrorSerializer.new(status: 400, resource: resource)
        expect(serializer.as_json).to eq expected_json_hash
      end
    end

    context 'with a title' do
      it 'will correctly generate the json for the error title' do
        expected_json_hash = {
          errors: [
            {
              status: 404,
              title: 'Not Found',
              detail: "Couldn't find resource at /api/v2/google"
            }
          ]
        }.as_json

        arguments = {
          status: 404,
          title: title,
          detail: detail
        }

        serializer = ErrorSerializer.new(arguments)
        expect(serializer.as_json).to eq expected_json_hash
      end
    end

    context 'with a hash of errors' do
      it 'will correctly generate the json for the errors from the hash' do
        expected_json_hash = {
          errors: [
            {
              status: 400,
              source: { pointer: '/data/attributes/name' },
              title: "can't be blank",
              detail: "Name can't be blank"
            },
            {
              status: 400,
              source: { pointer: '/data/attributes/email' },
              title: 'must be unique',
              detail: 'Email must be unique'
            }
          ]
        }.as_json

        serializer = ErrorSerializer.new(status: 400, hash: error_hash)
        expect(serializer.as_json).to eq expected_json_hash
      end
    end
  end

  class MockResource
    extend ActiveModel::Translation

    def errors
      @errors ||= build_errors
    end

    private

    def build_errors
      ActiveModel::Errors.new(self).tap do |errors|
        errors.add(:name, 'must be in ALL CAPS')
        errors.add(:name, 'must contain a ?')
        errors.add(:email, 'has already been taken')
      end
    end
  end
end
