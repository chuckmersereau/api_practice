require 'spec_helper'
require 'savon/mock/spec_helper'

describe InsightsController do
  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
    @designation_account = create(:designation_account, designation_number: '2716653')
    @account_list.designation_accounts << @designation_account
  end

  # set Savon in and out of mock mode
  before(:all) { savon.mock! }
  after(:all)  { savon.unmock! }

  # Disallow external requests
  include Savon::SpecHelper

  it 'returns analysis columns' do
    creds = { name: ENV.fetch('OBIEE_KEY'), password: ENV.fetch('OBIEE_SECRET') }
    fixture = File.read('spec/fixtures/obiee_auth_client.xml')
    savon.expects(:logon).with(message: creds).returns(fixture)
    results_fixture = File.read('spec/fixtures/obiee_report_results.xml')
    run_params = { report: { reportPath: '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations' },
                   outputFormat: 'SAWRowsetAndData',
                   executionOptions:
                      { async: '',
                        maxRowsPerPage: -1,
                        refresh: true,
                        presentationInfo: true,
                        type: '' },
                   reportParams: { filterExpressions: '',
                                   variables: { name: 'mpdxRecurrDesig', value: '2716653' }
                   },
                   sessionID: 'sessionid22091522cru' }
    savon.expects(:executeXMLQuery).with(message: run_params).returns(results_fixture)

    get :index
    expect(assigns(:recommnds)).to eq('Column0' => '0', 'Column1' => 'Test Desig (2716653)')
  end

  it 'it calls the creates action and adds a recommendation result record' do
    expect do
      post :create, selectedRecurringContactId: '12346234', selResult: 'Contacted - Received an Increase'
    end.to change { RecurringRecommendationResult.count }.by 1
  end
end
