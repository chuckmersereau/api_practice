require 'rails_helper'

RSpec.describe MailChimp::Importer::Matcher do
  let(:mail_chimp_account) { build(:mail_chimp_account) }
  let(:account_list) { mail_chimp_account.account_list }

  subject { described_class.new(mail_chimp_account) }

  context '#find_matching_people' do
    let(:first_email) { 'EMAIL@gmail.com' }
    let(:formatted_member_infos) do
      [
        {
          email: first_email,
          first_name: 'First Name',
          last_name: 'Last Name',
          greeting: 'Greeting',
          groupings: 'Random Grouping',
          status: 'subscribed'
        },
        {
          email: 'second_email@gmail.com',
          first_name: 'Second First Name',
          last_name: 'Second Last Name',
          greeting: 'Second Greeting',
          groupings: 'Second Random Grouping',
          status: 'subscribed'
        }
      ]
    end

    let(:contact) { create(:contact, account_list: account_list) }

    let!(:person) do
      create(:person, contacts: [contact],
                      primary_email_address: build(:email_address, email: first_email.downcase))
    end

    it 'returns a hash of people matching mail chimp member_infos' do
      expect(subject.find_matching_people(formatted_member_infos)).to eq(
        person.id => {
          'email' => 'EMAIL@gmail.com',
          'first_name' => 'First Name',
          'last_name' => 'Last Name',
          'greeting' => 'Greeting',
          'groupings' => 'Random Grouping',
          'status' => 'subscribed'
        }
      )
    end
  end
end
