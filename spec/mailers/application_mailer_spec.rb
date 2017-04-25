require 'rails_helper'

describe ApplicationMailer do
  let(:mailers_queue) { Sidekiq::Queue.all.find { |queue| queue.name == 'mailers' } }

  before do
    Sidekiq::Testing.fake!
  end

  it 'queues jobs to mailers queue by default' do
    expect { ApplicationMailer.delay.test }.to change {
      Sidekiq::Extensions::DelayedMailer.jobs.select { |job| job['queue'] == 'mailers' }.size
    }.by(1)
      .and change {
             Sidekiq::Extensions::DelayedMailer.jobs.size
           }.by(1)
  end

  it 'allows queueing to a specified queue' do
    expect { ApplicationMailer.delay(queue: 'my_special_queue').test }.to change {
      Sidekiq::Extensions::DelayedMailer.jobs.select { |job| job['queue'] == 'my_special_queue' }.size
    }.by(1)
      .and change {
             Sidekiq::Extensions::DelayedMailer.jobs.size
           }.by(1)
  end
end
