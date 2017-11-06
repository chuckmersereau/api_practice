require 'rails_helper'

describe CredentialValidator do
  let(:record) { build(:organization_account) }
  let(:validator) { described_class.new({}) }
  let(:api) { FakeApi.new }

  it 'should not add error if the record is missing an org' do
    record.organization = nil
    record.valid?
    expect(record.errors.full_messages).not_to include(
      _('Your credentials for %{org} are invalid.').localize % { org: record.organization }
    )
  end

  it 'should not add error if the record is missing a person' do
    record.person = nil
    record.valid?
    expect(record.errors.full_messages).not_to include(
      _('Your credentials for %{org} are invalid.').localize % { org: record.organization }
    )
  end

  context 'token is nil' do
    before do
      record.token = nil
    end

    it 'should add error if the record is missing username' do
      record.username = nil
      record.valid?
      expect(record.errors.full_messages).to include(
        _('Your credentials for %{org} are invalid.').localize % { org: record.organization }
      )
    end

    it 'should add error if the record is missing password' do
      record.password = nil
      record.valid?
      expect(record.errors.full_messages).to include(
        _('Your credentials for %{org} are invalid.').localize % { org: record.organization }
      )
    end
  end

  context 'token is not nil' do
    before do
      record.token = 'abc-123'
    end

    it 'should not add error if the record is missing username' do
      record.username = nil
      record.valid?
      expect(record.errors.full_messages).to_not include(
        _('Your credentials for %{org} are invalid.').localize % { org: record.organization }
      )
    end

    it 'should not add error if the record is missing password' do
      record.password = nil
      record.valid?
      expect(record.errors.full_messages).to_not include(
        _('Your credentials for %{org} are invalid.').localize % { org: record.organization }
      )
    end
  end

  it 'should add error if the credentials are invalid' do
    allow(record.organization).to receive(:api) { api }
    allow(api).to receive(:validate_credentials) { false }
    validator.validate(record)
    expect(record.errors.full_messages).to eq(
      [_('Your credentials for %{org} are invalid.').localize % { org: record.organization }]
    )
  end

  it 'should not add error if an error already exists' do
    record.password = nil
    expect do
      record.valid?
    end.to change { record.errors.full_messages }
    expect do
      record.valid?
    end.not_to change { record.errors.full_messages }
  end
end
