require 'spec_helper'

describe SidekiqMonitor do
  before do
    ENV['SIDEKIQ_WARN_EMAILS'] = 'dev@example.com, dev2@example.com'
    ENV['SIDEKIQ_WARN_MIN_PROCS'] = '2'
    ENV['SIDEKIQ_WARN_MIN_PROCS_INTERVAL'] = '60'
    ENV['SIDEKIQ_WARN_DEFAULT_QUEUE_LATENCY'] = '600'
    ENV['SIDEKIQ_WARN_STUCK_THREADS_FREE'] = '5'
    ENV['SIDEKIQ_WARN_STUCK_ENQUEUED'] = '100'
    ENV['SIDEKIQ_WARN_STUCK_INTERVAL'] = '30'
  end

  def stub_stats(stats)
    expect(Sidekiq::Stats).to receive(:new).and_return(double(stats))
  end

  def stub_processes_threads(*proc_threads)
    expect(Sidekiq::ProcessSet).to receive(:new).and_return(proc_threads.map { |c| { 'concurrency' => c } })
  end

  def expect_mail
    mail = double
    expect(ActionMailer::Base).to receive(:mail).and_return(mail)
    expect(mail).to receive(:deliver)
  end

  it 'does not notify in normal conditions' do
    stub_stats(default_queue_latency: 1.0, enqueued: 1, workers_size: 1)
    stub_processes_threads(5, 5)
    expect(ActionMailer::Base).not_to receive(:mail)
    SidekiqMonitor.notify_if_problem
  end

  it 'notifies if fewer than min processes' do
    stub_stats(default_queue_latency: 1.0, enqueued: 1, workers_size: 1)
    stub_processes_threads(5)
    expect(SidekiqMonitor).to receive(:sleep).with(60.0)
    expect_mail
    SidekiqMonitor.notify_if_problem
  end

  it 'notifies too many jobs enqueued but enough threads free over a time interval' do
    stub_stats(default_queue_latency: 1.0, enqueued: 1000, workers_size: 10)
    stub_processes_threads(20, 20)
    expect(SidekiqMonitor).to receive(:sleep).with(30.0)
    expect_mail
    SidekiqMonitor.notify_if_problem
  end

  it 'does not error if no processors are running' do
    stub_processes_threads
    stub_stats(default_queue_latency: 1.0, enqueued: 1, workers_size: 1)
    expect(SidekiqMonitor).to receive(:sleep).with(60.0)
    expect_mail
    SidekiqMonitor.notify_if_problem
  end
end
