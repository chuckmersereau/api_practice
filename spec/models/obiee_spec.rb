require 'spec_helper'
require 'savon/mock/spec_helper'

describe Obiee do

  #Disallow external requests
  include Savon::SpecHelper

# set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  obiee = ''
  SESSION_ID = 'sessionid22091522cru'
  PATH = '/shared/Insight/Siebel Recurring Monthly/Recurring Designation Test Query'
  SQL = 'SELECT
   0 s_0,
   "CCCi Transaction Analytics"."- Designation"."Designation Name" s_1
FROM "CCCi Transaction Analytics"
WHERE ("- Designation"."Designation Name" = ''Test Desig ((2716653)'')
ORDER BY 1, 2 ASC NULLS LAST
FETCH FIRST 10000000 ROWS ONLY'

  it 'gets a session id' do
    creds =  { name: APP_CONFIG['obiee_key'], password: APP_CONFIG['obiee_secret'] }
    fixture = File.read('spec/fixtures/obiee_auth_client.xml')
    savon.expects(:logon).with(message: creds).returns(fixture)
    obiee = Obiee.new
    session_id = obiee.session_id
    expect(session_id).to eq(SESSION_ID)
  end

  it 'gets report sql with session id' do
    rpt_sql_fixture = File.read('spec/fixtures/obiee_report_sql.xml')
    report_params = { reportRef: { reportPath: PATH },
                      reportParams: { filterExpressions: '',
                                      variables: {}
                      },
                      sessionID: SESSION_ID }

    savon.expects(:generateReportSQL).with(message: report_params).returns(rpt_sql_fixture)
    report_sql = obiee.report_sql SESSION_ID, PATH, {}

    expect(report_sql).to eq('SELECT
   0 s_0,
   "CCCi Transaction Analytics"."- Designation"."Designation Name" s_1
FROM "CCCi Transaction Analytics"
ORDER BY 1, 2 ASC NULLS LAST
FETCH FIRST 10000000 ROWS ONLY')
  end

  it 'no sql when no session_id' do
    rpt_sql_fixture = File.read('spec/fixtures/obiee_report_sql.xml')
    report_params = { reportRef: { reportPath: PATH },
                      reportParams: { filterExpressions: '',
                                      variables: {}
                      },
                      sessionID: SESSION_ID }

    savon.expects(:generateReportSQL).with(message: report_params).returns(rpt_sql_fixture)
    expect { obiee.report_sql('', PATH, {}) }.to raise_error(Savon::ExpectationError)
  end

  it 'fails when no session_id' do
    rpt_sql_fixture = File.read('spec/fixtures/obiee_report_sql.xml')
    report_params = { reportRef: { reportPath: PATH },
                      reportParams: { filterExpressions: '',
                                      variables: {}
                      },
                      sessionID: SESSION_ID }
    savon.expects(:generateReportSQL).with(message: report_params).returns(rpt_sql_fixture)
    expect { obiee.report_sql('', PATH, {}) }.to raise_error(Savon::ExpectationError)
  end

  it 'fails when no report path' do
    rpt_sql_fixture = File.read('spec/fixtures/obiee_report_sql.xml')
    report_params = { reportRef: { reportPath: PATH },
                      reportParams: { filterExpressions: '',
                                     variables: {}
                      },
                      sessionID: SESSION_ID }
    savon.expects(:generateReportSQL).with(message: report_params).returns(rpt_sql_fixture)
    #No Path
    expect { obiee.report_sql(SESSION_ID, '', {}) }.to raise_error(Savon::ExpectationError)
  end

  it 'gets report results with session id' do
    results_fixture = File.read('spec/fixtures/obiee_report_results.xml')
    run_params = { sql: SQL,
                   outputFormat: 'SAWRowsetSchemaAndData',
                   executionOptions:
                       { async: '',
                         maxRowsPerPage: -1,
                         refresh: true,
                         presentationInfo: true,
                         type: '' },
                   sessionID: SESSION_ID }
    savon.expects(:executeSQLQuery).with(message: run_params).returns(results_fixture)
    report_results = obiee.report_results(SESSION_ID, SQL)
    expect(report_results).to include('<Row><Column0>0</Column0><Column1>Test Desig (2716653)</Column1></Row><')
  end

  it 'fails to get report results when no session id' do
    results_fixture = File.read('spec/fixtures/obiee_report_results.xml')
    run_params = { sql: SQL,
                   outputFormat: 'SAWRowsetSchemaAndData',
                   executionOptions:
                       { async: '',
                         maxRowsPerPage: -1,
                         refresh: true,
                         presentationInfo: true,
                         type: '' },
                   sessionID: SESSION_ID }
    savon.expects(:executeSQLQuery).with(message: run_params).returns(results_fixture)
    #No Session ID
    expect { obiee.report_results('', SQL) }.to raise_error(Savon::ExpectationError)
  end

  it 'fails to get report results when no sql' do
    results_fixture = File.read('spec/fixtures/obiee_report_results.xml')
    run_params = { sql: SQL,
                   outputFormat: 'SAWRowsetSchemaAndData',
                   executionOptions:
                       { async: '',
                         maxRowsPerPage: -1,
                         refresh: true,
                         presentationInfo: true,
                         type: '' },
                   sessionID: SESSION_ID }
    savon.expects(:executeSQLQuery).with(message: run_params).returns(results_fixture)
    expect { obiee.report_results(SESSION_ID, '') }.to raise_error(Savon::ExpectationError)
  end
end
