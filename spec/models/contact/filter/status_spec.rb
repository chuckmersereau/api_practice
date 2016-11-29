require 'spec_helper'

RSpec.describe Contact::Filter::Status do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config(account_list)).to include(default_selection: %w(active null),
                                                              multiple: true,
                                                              name: :status,
                                                              options: [{ name: '-- All Active --', id: 'active' },
                                                                        { name: '-- All Hidden --', id: 'hidden' },
                                                                        { name: '-- None --', id: 'null' },
                                                                        { name: 'Never Contacted', id: 'Never Contacted' },
                                                                        { name: 'Ask in Future', id: 'Ask in Future' },
                                                                        { name: 'Cultivate Relationship', id: 'Cultivate Relationship' },
                                                                        { name: 'Contact for Appointment', id: 'Contact for Appointment' },
                                                                        { name: 'Appointment Scheduled', id: 'Appointment Scheduled' },
                                                                        { name: 'Call for Decision', id: 'Call for Decision' },
                                                                        { name: 'Partner - Financial', id: 'Partner - Financial' },
                                                                        { name: 'Partner - Special', id: 'Partner - Special' },
                                                                        { name: 'Partner - Pray', id: 'Partner - Pray' },
                                                                        { name: 'Not Interested', id: 'Not Interested' },
                                                                        { name: 'Unresponsive', id: 'Unresponsive' },
                                                                        { name: 'Never Ask', id: 'Never Ask' },
                                                                        { name: 'Research Abandoned', id: 'Research Abandoned' },
                                                                        { name: 'Expired Referral', id: 'Expired Referral' }],
                                                              parent: nil,
                                                              title: 'Status',
                                                              type: 'multiselect')
    end
  end
end
