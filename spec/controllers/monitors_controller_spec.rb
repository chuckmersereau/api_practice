require 'rails_helper'

describe MonitorsController do
  context '#lb' do
    it 'gives success because we have a valid database connection' do
      get :lb
      expect(response).to be_success
    end
  end

  context '#sidekiq' do
    it 'gives success if latency not too high' do
      expect(SidekiqMonitor).to receive(:queue_latency_too_high?) { false }
      get :sidekiq
      expect(response.status).to eq 200
    end

    it 'gives error status if latency too high' do
      expect(SidekiqMonitor).to receive(:queue_latency_too_high?) { true }
      get :sidekiq
      expect(response.status).to eq 500
    end
  end

  context '#commit' do
    it 'renders git GIT_COMMIT env var' do
      ENV['GIT_COMMIT'] = 'abc123'

      get :commit

      expect(response.body).to eq 'abc123'
    end
  end
end
