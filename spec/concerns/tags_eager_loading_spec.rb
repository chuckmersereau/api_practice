require 'spec_helper'

describe TagsEagerLoading do
  let(:contact) { create(:contact) }
  before do
    contact.tag_list = %w(a b)
    contact.save
  end

  it 'retrieves tags with no eager load' do
    expect(contact.tag_list).to eq(%w(a b))
  end

  it 'retrieves tags with an eager load association' do
    expect(Contact.includes(:tags).first.tag_list).to eq(%w(a b))
  end
end
