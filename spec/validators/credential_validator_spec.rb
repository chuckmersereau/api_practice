require 'rails_helper'

describe CredentialValidator do
  before(:each) do
    @record = FactoryGirl.build(:organization_account)
    @validator = CredentialValidator.new({})
  end

  describe 'when using requires credentials' do
    before(:each) do
      allow(@record).to receive(:requires_credentials?) { true }
    end

    it 'should not add error if the record is missing an org' do
      @record.organization = nil
      @record.valid?
      expect(@record.errors.full_messages).not_to include(
        _('Your credentials for %{org} are invalid.').localize % { org: @record.organization }
      )
    end

    it 'should not add error if the record is missing username' do
      @record.username = nil
      @record.valid?
      expect(@record.errors.full_messages).not_to include(
        _('Your credentials for %{org} are invalid.').localize % { org: @record.organization }
      )
    end

    it 'should add error if the record is missing password' do
      @record.password = nil
      @record.valid?
      expect(@record.errors.full_messages).not_to include(
        _('Your credentials for %{org} are invalid.').localize % { org: @record.organization }
      )
    end

    it 'should add error if the credentials are invalid' do
      @api = FakeApi.new
      allow(@record.organization).to receive(:api) { @api }
      allow(@api).to receive(:validate_credentials) { false }
      @validator.validate(@record)
      expect(@record.errors.full_messages).to eq(
        [_('Your credentials for %{org} are invalid.').localize % { org: @record.organization }]
      )
    end

    it 'should not add error if an error already exists' do
      @record.password = nil
      expect do
        @record.valid?
      end.to change { @record.errors.full_messages }
      expect do
        @record.valid?
      end.not_to change { @record.errors.full_messages }
    end
  end

  describe 'when credentials is not required' do
    before(:each) do
      allow(@record).to receive(:requires_credentials?) { false }
    end

    it 'should not add error if the credentials are blank' do
      @record.username = nil
      @record.password = nil
      @validator.validate(@record)
      expect(@record.errors.full_messages).not_to include(
        _('Your credentials for %{org} are invalid.').localize % { org: @record.organization }
      )
    end
  end
end
