require 'spec_helper'
require 'rails'
require 'documentation_helper'

RSpec.describe DocumentationHelper, type: :service do
  before do
    path = Pathname.new('/mock/project-name')

    allow(Rails).to receive(:root)
      .and_return(path)
  end

  describe '#initialize' do
    context 'with a single resource' do
      it 'returns a resource array' do
        helper = build_helper(resource: :emails)
        expect(helper.resource).to match [:emails]
      end
    end

    context 'with multiple references' do
      it 'returns the references in an array' do
        helper = build_helper(resource: [:contacts, :people, :emails])
        expect(helper.resource).to match [:contacts, :people, :emails]
      end
    end
  end

  describe '#insert_documentation_for' do
    it 'delegates to the other document_for methods' do
      action  = :create
      context = build_mock_context
      helper  = build_helper

      expect(helper)
        .to receive(:document_parameters_for)
        .with(action: action, context: context)
      expect(helper)
        .to receive(:document_response_fields_for)
        .with(action: action, context: context)

      helper.insert_documentation_for(action: action, context: context)
    end
  end

  describe '#document_parameters_for' do
    let(:helper) do
      filepath = 'spec/support/documentation/test/contacts.yml'
      build_helper(filepath: filepath)
    end

    it 'sends :parameter to context with non-ignored fields' do
      context = build_mock_context

      data = helper.data_for(type: :parameters, action: :create).deep_dup

      data.each do |name, attributes|
        description = attributes.delete(:description)

        if attributes.key?(:ignore)
          expect(context)
            .not_to receive(:parameter)
            .with(name, description, attributes)
        else
          expect(context)
            .to receive(:parameter)
            .with(name, description, attributes)
        end
      end

      helper.document_parameters_for(action: :create, context: context)
    end
  end

  describe '#document_response_fields_for' do
    let(:helper) do
      filepath = 'spec/support/documentation/test/contacts.yml'
      build_helper(filepath: filepath)
    end

    it 'sends :response_field to context with non-ignored fields' do
      context = build_mock_context

      data = helper.data_for(type: :response_fields, action: :create).deep_dup

      data.each do |name, attributes|
        description = attributes.delete(:description)

        if attributes.key?(:ignore)
          expect(context)
            .not_to receive(:response_field)
            .with(name, description, attributes)
        else
          expect(context)
            .to receive(:response_field)
            .with(name, description, attributes)
        end
      end

      helper.document_response_fields_for(action: :create, context: context)
    end
  end

  describe '#document_scope' do
    context 'for an entity (single resource passed)' do
      it 'returns the scope for organizing the documentation' do
        helper = build_helper(resource: :contacts)
        expect(helper.document_scope).to eq :entities_contacts

        helper = build_helper(resource: :people)
        expect(helper.document_scope).to eq :entities_people
      end
    end

    context 'for an api (multiple resource passed)' do
      it 'returns the scope for organizing the documentation' do
        helper = build_helper(resource: [:people, :emails])
        expect(helper.document_scope).to eq :people_api_emails

        helper = build_helper(resource: [:contacts, :addresses])
        expect(helper.document_scope).to eq :contacts_api_addresses
      end
    end
  end

  describe '#filename' do
    it 'returns the filename expected based on the resource' do
      helper = build_helper(resource: [:contacts, :people, :emails])
      expect(helper.filename).to eq 'emails.yml'
    end
  end

  describe '#filepath' do
    it 'returns the filepath based on the resource' do
      base_path    = Rails.root.to_s
      path_of_file = 'spec/support/documentation/test/contacts/people/emails.yml'
      resource     = [:test, :contacts, :people, :emails]
      helper       = DocumentationHelper.new(resource: resource)

      expect(helper.filepath).to eq "#{base_path}/#{path_of_file}"
    end
  end

  describe '#title_for' do
    let(:helper) { build_helper(resource: :email_addresses) }

    it 'returns the title for index' do
      expect(helper.title_for(:index)).to eq 'List Email Addresses'
    end

    it 'returns the title for show' do
      expect(helper.title_for(:show)).to eq 'Retrieve an Email Address'
    end

    it 'returns the title for create' do
      expect(helper.title_for(:create)).to eq 'Create an Email Address'
    end

    it 'returns the title for update' do
      expect(helper.title_for(:update)).to eq 'Update an Email Address'
    end

    it 'returns the title for delete' do
      expect(helper.title_for(:delete)).to eq 'Delete an Email Address'
    end

    it 'returns the title for bulk create' do
      expect(helper.title_for(:bulk_create)).to eq 'Bulk create Email Addresses'
    end

    it 'returns the title for bulk update' do
      expect(helper.title_for(:bulk_update)).to eq 'Bulk update Email Addresses'
    end

    it 'returns the title for bulk delete' do
      expect(helper.title_for(:bulk_delete)).to eq 'Bulk delete Email Addresses'
    end

    it 'will return a custom title defined in the yml' do
      expect(helper.title_for(:custom_action)).to eq 'My Custom Title'
    end
  end

  describe '#description_for' do
    let(:helper) { build_helper }

    context 'without a custom description' do
      it 'returns the title for the action' do
        expect(helper.description_for(:delete)).to eq helper.title_for(:delete)
      end
    end

    context 'with a custom description' do
      it 'returns the title for the action' do
        expected_desc = 'This is the endpoint for Creating an Email Address'
        expect(helper.description_for(:create)).to eq expected_desc
      end
    end
  end

  describe '#raw_data' do
    let(:expected_data) { YAML.load_file(test_filepath).deep_symbolize_keys }

    it 'returns the raw hash data found in the yaml doc file' do
      helper = build_helper
      expect(helper.raw_data).to eq expected_data
    end
  end

  describe '#data_for' do
    context "when the YAML data doesn't have a data key" do
      let(:expected_data) do
        {
          'attributes.created_at': {
            description: 'The timestamp of when this resource was created',
            type: 'ISO8601 timestamp'
          },
          'attributes.email': {
            description: 'The actual email address that this Email Address resource represents',
            required: true,
            type: 'string'
          },
          'attributes.primary': {
            description: "Whether or not the `email` is the owner's primary email address",
            type: 'boolean'
          },
          'attributes.updated_at': {
            description: 'The timestamp of when this resource was last updated',
            type: 'ISO8601 timestamp'
          },
          'attributes.updated_in_db_at': {
            description: 'This is to be used as a reference for the last time the resource was updated in the remote database - specifically for when data is updated while the client is offline.',
            type: 'ISO8601 timestamp',
            required: true
          },
          'relationships.account_list.data.id': {
            description: 'The `id` of the Account List needed for creating',
            type: 'number',
            required: true
          },
          'relationships.emails.data': {
            description: 'An array of Emails sent by this Email Address',
            type: '[Email]'
          }
        }
      end

      it 'returns the transformed data with additional field data' do
        helper = build_helper

        expect(helper.data_for(type: :response_fields, action: :create))
          .to eq expected_data
      end
    end

    context 'when the YAML data has a data key' do
      let(:expected_data) do
        {
          'data': {
            description: 'An array of Email Address objects',
            type: '[Email Address]'
          }
        }
      end

      it 'returns the transformed data sans ignored attributes' do
        helper = build_helper

        expect(helper.data_for(type: :response_fields, action: :index))
          .to eq expected_data
      end
    end
  end

  def build_helper(resource: nil, filepath: test_filepath)
    resource ||= [:test, :contacts, :people, :emails]

    DocumentationHelper.new(resource: resource, filepath: filepath)
  end

  def build_mock_context
    double('context', parameter: nil, response_field: nil)
  end

  def test_filepath
    'spec/support/documentation/test/contacts/people/emails.yml'
  end
end
