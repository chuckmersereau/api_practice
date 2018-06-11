require 'rails_helper'

describe RunOnce::SendGDPRUnsubscribesWorker do
  let(:emails) { ['test@gmail.com', 'check@aol.com', 'fake@email.com'] }

  subject { described_class.new.perform(emails) }

  it 'sends two emails' do
    account_list = create(:user_with_full_account).account_lists.first
    contact1 = create(:contact_with_person, account_list: account_list, send_newsletter: 'Email')
    contact1.primary_person.email = emails[0]
    contact2 = create(:contact_with_person, account_list: account_list, send_newsletter: 'Both')
    contact2.primary_person.email = emails[1]

    expect { subject }.to change { Sidekiq::Extensions::DelayedMailer.jobs.size }.by(2)

    job = Sidekiq::Extensions::DelayedMailer.jobs.last
    parsed_args = YAML.safe_load(job['args'].first, [Symbol])
    email_arg = parsed_args.last.last[:email]
    # they might be in any order, what matters is that a job was enqueued with one of the emails
    expect(emails[0..1].include?(email_arg)).to be true
  end
end
