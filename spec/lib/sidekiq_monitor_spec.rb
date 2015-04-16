require 'spec_helper'

describe SidekiqMonitor do
  before do
    APP_CONFIG['sidekiq_warn_emails'] = 'dev@example.com, dev2@example.com'
    APP_CONFIG['sidekiq_warn_min_procs'] = '2'
    APP_CONFIG['sidekiq_warn_min_procs_interval'] = '60'
    APP_CONFIG['sidekiq_warn_default_queue_latency'] = '600'
    APP_CONFIG['sidekiq_warn_stuck_threads_free'] = '5'
    APP_CONFIG['sidekiq_warn_stuck_enqueued'] = '100'
    APP_CONFIG['sidekiq_warn_stuck_interval'] = '30'
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

  it 'notifies if queue latency above threshold' do
    stub_stats(default_queue_latency: 5000.1, enqueued: 1, workers_size: 1)
    stub_processes_threads(5, 5)
    expect_mail
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
