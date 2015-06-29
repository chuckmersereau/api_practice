require 'spec_helper'

describe ErrorsController do
  render_views

  describe 'page not found' do
    it 'renders error page' do
      get 'error_404'
      expect(response).to render_template 'application/error'
    end
  end
end
