require 'rails_helper'

describe ActsAsTaggableOn::Tagging do
  let(:bob) { create(:contact) }
  let!(:tag) { create(:tag) }

  it 'should not allow duplicate tags' do
    expect do
      ActsAsTaggableOn::Tagging.create(tag: tag, taggable: bob, context: 'test')
    end.to change { ActsAsTaggableOn::Tagging.count }

    expect do
      ActsAsTaggableOn::Tagging.create(tag: tag, taggable: bob, context: 'test')
    end.to_not change { ActsAsTaggableOn::Tagging.count }
  end
end
