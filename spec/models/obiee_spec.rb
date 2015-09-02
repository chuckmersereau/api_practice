require 'spec_helper'
require 'savon/mock/spec_helper'

describe Obiee do
  # Disallow external requests
  include Savon::SpecHelper

  let(:obiee) { Obiee.new }
  let(:session_id) { 'sessionid22091522cru' }
  let(:report_path) { '/shared/Insight/Siebel Recurring Monthly/Recurring Designation Test Query' }
  let(:results_fixture) { File.read('spec/fixtures/obiee_report_sql.xml') }

  before do
    savon.mock!

    creds = { name: ENV.fetch('OBIEE_KEY'), password: ENV.fetch('OBIEE_SECRET') }
    fixture = File.read('spec/fixtures/obiee_auth_client.xml')
    savon.expects(:logon).with(message: creds).returns(fixture)
  end

  def report_params
    { report: { reportPath: report_path },
      outputFormat: 'SAWRowsetAndData',
      executionOptions:
        { async: '',
          maxRowsPerPage: -1,
          refresh: true,
          presentationInfo: true,
          type: '' },
      reportParams: { filterExpressions: '',
                      variables: {}
    },
      sessionID: session_id }
  end

  after { savon.unmock! }

  it 'gets a session id' do
    expect(obiee.session_id).to eq(session_id)
  end

  it 'fails when no report path' do
    savon.expects(:executeXMLQuery).with(message: report_params).returns(results_fixture)
    # No Path
    expect { obiee.report_results(session_id, '', {}) }.to raise_error(Savon::ExpectationError)
  end

  it 'gets report results when session id and report path are present' do
    results_fixture = File.read('spec/fixtures/obiee_report_results.xml')
    savon.expects(:executeXMLQuery).with(message: report_params).returns(results_fixture)
    report_results = obiee.report_results(session_id, report_path)
    expect(report_results).to include('<Row><Column0>0</Column0><Column1>Test Desig (2716653)</Column1></Row><')
  end

  it 'fails to get report results when no session id' do
    savon.expects(:executeXMLQuery).with(message: report_params).returns(results_fixture)
    # No Session ID
    expect { obiee.report_results('', report_path) }.to raise_error(Savon::ExpectationError)
  end
end
