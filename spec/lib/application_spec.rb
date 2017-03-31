require 'rails_helper'

describe Mpdx::Application do
  describe 'middleware' do
    it 'uses Rack::MethodOverride' do
      expect(described_class.middleware).to include(Rack::MethodOverride)
    end
  end
end
