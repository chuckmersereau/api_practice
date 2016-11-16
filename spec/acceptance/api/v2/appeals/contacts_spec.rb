require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts' do
  let(:resource_type) { 'contact' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.id }
  let!(:contact) { create(:contact, account_list_id: account_list_id) }
  let(:id) { contact.id }

  context 'authorized user' do
    before do
      appeal.contacts << contact
      api_login(user)
    end
    get '/api/v2/appeals/:appeal_id/contacts' do
      parameter 'account_list_id',              'Account List ID', required: true
      response_field :data,                     'Data', 'Type' => 'Array'
      example_request 'list contacts of appeal of account list' do
        expect(resource_object.keys).to eq %w( name pledge-amount pledge-frequency pledge-currency pledge-currency-symbol
                                               pledge-start-date pledge-received status deceased notes notes-saved-at next-ask no-appeals likely-to-give
                                               church-name send-newsletter magazine last-activity last-appointment last-letter last-phone-call last-pre-call
                                               last-thank avatar square-avatar referrals-to-me-ids tag-list uncompleted-tasks-count timezone donor-accounts )
        expect(status).to eq 200
      end
    end
    get '/api/v2/appeals/:appeal_id/contacts/:id' do
      parameter 'account_list_id',              'Account List ID', required: true
      with_options scope: [:data, :attributes] do
        response_field 'name',                    'Name', 'Type' => 'String'
        response_field 'pledge-amount',           'Pledge Amount', 'Type' => 'Decimal'
        response_field 'pledge-frequency',        'Pledge Frequency', 'Type' => 'Decimal'
        response_field 'pledge-currency',         'Pledge Currency', 'Type' => 'String'
        response_field 'pledge-currency-symbol',  'Pledge Currency Symbol', 'Type' => 'String'
        response_field 'pledge-start-date',       'Pledge Start Date', 'Type' => 'Date'
        response_field 'pledge-received',         'Pledge Received', 'Type' => 'Boolean'
        response_field 'status',                  'Status', 'Type' => 'String'
        response_field 'deceased',                'Deceased', 'Type' => 'Boolean'
        response_field 'notes',                   'Notes', 'Type' => 'String'
        response_field 'notes-saved-at',          'Notes saved at', 'Type' => 'Date'
        response_field 'next-ask',                'Next ask', 'Type' => 'Date'
        response_field 'no-appeals',              'No Appeals', 'Type' => 'Boolean'
        response_field 'likely-to-give',          'Likely to Give', 'Type' => 'String'
        response_field 'church-name',             'Church Name', 'Type' => 'String'
        response_field 'send-newsletter',         'Send Newsletter', 'Type' => 'String'
        response_field 'magazine',                'Magazine', 'Type' => 'Boolean'
        response_field 'last-activity',           'Last Activity', 'Type' => 'Date'
        response_field 'last-appointment',        'Last Appointment', 'Type' => 'Date'
        response_field 'last-letter',             'Last letter', 'Type' => 'Date'
        response_field 'last-phone-call',         'Last phone call', 'Type' => 'Date'
        response_field 'last-pre-call',           'Last Pre-Call', 'Type' => 'Date'
        response_field 'last-thank',              'Last Thank', 'Type' => 'Date'
        response_field 'avatar',                  'Avatar', 'Type' => 'String'
        response_field 'square-avatar',           'Square Avatar', 'Type' => 'String'
        response_field 'referrals-to-me-ids',     'Referrals to me IDs', 'Type' => 'Array'
        response_field 'tag-list',                'Tag List', 'Type' => 'Array'
        response_field 'uncompleted-tasks-count', 'Uncompleted Tasks count', 'Type' => 'Integer'
        response_field 'timezone',                'Timezone', 'Type' => 'String'
        response_field 'donor-accounts',          'Donor Accounts', 'Type' => 'Array'
      end
      example_request 'get contact' do
        expect(resource_object.keys).to eq %w( name pledge-amount pledge-frequency pledge-currency pledge-currency-symbol
                                               pledge-start-date pledge-received status deceased notes notes-saved-at next-ask no-appeals likely-to-give
                                               church-name send-newsletter magazine last-activity last-appointment last-letter last-phone-call last-pre-call
                                               last-thank avatar square-avatar referrals-to-me-ids tag-list uncompleted-tasks-count timezone donor-accounts )
        expect(status).to eq 200
      end
    end
    delete '/api/v2/appeals/:appeal_id/contacts/:id' do
      parameter 'account_list_id',              'Account List ID', required: true
      parameter 'id',                           'ID', required: true
      example_request 'delete contact from appeal' do
        expect(status).to eq 200
      end
    end
  end
end
