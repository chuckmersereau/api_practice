require 'spec_helper'

describe SidekiqMemNotifier do
  before { ENV['CONTAINER_MB'] = '1000' }
  subject { SidekiqMemNotifier }

  context '#start' do
    it 'defaults threshold to 95% of container memory, and starts check thread' do
      expect(subject).to receive(:sidekiq_running?) { true }
      expect(subject).to receive(:start_monitor_thread)
      subject.start
      expect(subject.threshold_mb).to eq(950)
    end
  end

  context '#start_monitor_thread' do
    it 'creates a new thread to do the loop with priority 1' do
      thread = double
      expect(Thread).to receive(:new) { thread }
      expect(thread).to receive(:priority=).with(1)
      subject.start_monitor_thread
    end
  end

  context '#check_memory_iteration' do
    before do
      subject.threshold_mb = 950
      expect(subject).to receive(:sleep).with(5)
    end

    it 'just sleeps if within threshold' do
      expect(subject).to receive(:rss_mb) { 949.1 }
      expect(subject).to_not receive(:memory_threshold_exceeded)
      subject.check_memory_iteration
    end

    it 'tries to GC and notifies if above threshold' do
      expect(subject).to receive(:rss_mb).ordered { 971.1 }
      expect(GC).to receive(:start)
      expect(subject).to receive(:rss_mb).ordered { 951.1 }
      expect(subject).to receive(:memory_threshold_exceeded).with(951.1)
      subject.check_memory_iteration
    end
  end

  context '#memory_threshold_exceeded' do
    it 'logs messages and sends an notification email' do
      expect(subject).to receive(:threshold_exceeded_msgs).with(951) { ['Oops', ':('] }
      expect(Sidekiq.logger).to receive(:error).with('Oops').ordered
      expect(Sidekiq.logger).to receive(:error).once.with(':(').ordered

      expect(subject).to receive(:notify_by_email).with(['Oops', ':('])

      subject.memory_threshold_exceeded(951)
    end
  end

  context '#threshold_exceeded_msgs' do
    it 'gives explanatory messages' do
      ENV['DYNO'] = 'worker.1'
      workers = [{ work: 1 }, { work: 2 }]
      expect(Sidekiq::Workers).to receive(:new) { workers }
      subject.threshold_mb = 950
      expected_msgs = [
        'SidekiqMemNotifier: Exceeded memory threshold (951.5 > 950 MB)',
        "ENV['DYNO']: worker.1",
        'All jobs: [{:work=>1}, {:work=>2}]'
      ]
      expect(subject.threshold_exceeded_msgs(951.5)).to eq expected_msgs
    end
  end

  context '#notify_by_email' do
    before do
      subject.last_time_emailed = nil
      ENV['SIDEKIQ_WARN_EMAILS'] = 'dev@mpdx.org, dev2@mpdx.org'
    end

    it 'sends a notification email the first time called' do
      expect do
        subject.notify_by_email(['Oops', ':('])
      end.to change(ActionMailer::Base.deliveries, :size).by(1)
      email = ActionMailer::Base.deliveries.last
      expect(email.from).to eq ['support@mpdx.org']
      expect(email.to).to include 'dev@mpdx.org'
      expect(email.to).to include 'dev2@mpdx.org'
      expect(email.subject).to eq 'Sidekiq memory threshold'
      expect(email.body.to_s).to eq "Oops\n:("
    end

    it 'does not send notifications when called again right away' do
      expect do
        subject.notify_by_email(['Oops', ':('])
        subject.notify_by_email(['Oops', ':('])
      end.to change(ActionMailer::Base.deliveries, :size).by(1)
    end

    it 'will email again after 2 hours' do
      expect do
        subject.notify_by_email(['Oops', ':('])
      end.to change(ActionMailer::Base.deliveries, :size).by(1)

      travel_to((2.hours + 1.second).since) do
        expect do
          subject.notify_by_email(['Oops', ':('])
        end.to change(ActionMailer::Base.deliveries, :size).by(1)
      end
    end
  end
end
