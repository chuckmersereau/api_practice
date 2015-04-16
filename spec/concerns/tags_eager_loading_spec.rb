require 'spec_helper'

describe TagsEagerLoading do
  let(:contact) { create(:contact) }
  before do
    contact.tag_list = %w(a b)
    contact.save
  end

  it 'retrieves tags with no eager load' do
    expect_correct_tag_list(contact.tag_list)
  end

  it 'retrieves tags with an eager load association' do
    expect_correct_tag_list(Contact.includes(:tags).first.tag_list)
  end

  def expect_correct_tag_list(tag_list)
    expect(tag_list).to eq(%w(a b))
    expect(tag_list.to_s).to eq('a, b')
  end
end
