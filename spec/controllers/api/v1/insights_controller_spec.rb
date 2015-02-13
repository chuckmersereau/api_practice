require 'spec_helper'
require "savon/mock/spec_helper"

describe Api::V1::InsightsController do

  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
    @designation_account = create(:designation_account, designation_number: '2716653')
    @account_list.designation_accounts << @designation_account
    @donor_account = create(:donor_account, account_number: '123456789')
  end

  #set Savon in and out of mock mode
  before(:all) { savon.mock! }
  after(:all)  { savon.unmock! }

  #Disallow external requests
  include Savon::SpecHelper

  it 'returns a string array' do

    creds = {name: APP_CONFIG['obiee_key'], password: APP_CONFIG['obiee_secret'] }
    fixture = File.read('spec/fixtures/obiee_auth_client.xml')
    savon.expects(:logon).with(message: creds).returns(fixture)

    rpt_sql_fixture = File.read('spec/fixtures/obiee_report_sql.xml')
    report_params = { reportRef: {reportPath: '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations'},
                      reportParams: {filterExpressions: '',
                                     variables: {:name=>"mpdxRecurrDesig", :value=>"2716653"}
                      },
                      sessionID: 'sessionid22091522cru'}
    savon.expects(:generateReportSQL).with(message: report_params ).returns(rpt_sql_fixture)

    results_fixture = File.read('spec/fixtures/obiee_report_results2.xml')
    run_params = {sql: 'SELECT
   0 s_0,
   "CCCi Transaction Analytics"."- Designation"."Designation Name" s_1
FROM "CCCi Transaction Analytics"
ORDER BY 1, 2 ASC NULLS LAST
FETCH FIRST 10000000 ROWS ONLY',
                  outputFormat: 'SAWRowsetSchemaAndData',
                  executionOptions:
                      {async: '',
                       maxRowsPerPage: -1,
                       refresh: true,
                       presentationInfo: true,
                       type: ''},
                  sessionID: 'sessionid22091522cru'}
    savon.expects(:executeSQLQuery).with(message: run_params ).returns(results_fixture)

    get :index, access_token: @user.access_token
    response.should be_success
    json = JSON.parse(response.body)
  end
end