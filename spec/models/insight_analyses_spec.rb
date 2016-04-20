require 'spec_helper'
require 'savon/mock/spec_helper'

describe 'InsightAnalyses' do
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:designation_account) { create(:designation_account, designation_number: '2716653') }
  let(:auth_fixture) { File.read('spec/fixtures/obiee_auth_client.xml') }
  let(:creds) { { name: ENV.fetch('OBIEE_KEY'), password: ENV.fetch('OBIEE_SECRET') } }
  let(:results_fixture) { File.read('spec/fixtures/obiee_report_results.xml') }

  # Disallow external requests
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock! }
  before do
    savon.expects(:logon).with(message: creds).returns(auth_fixture)
    savon.expects(:executeXMLQuery).with(message: report_params).returns(results_fixture)
  end
  after(:all) { savon.unmock! }

  def report_params
    { report: { reportPath: '/shared/MPD/Siebel Recurring Monthly/Recurring Gift Recommendations' },
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
  end

  it 'gets analysis results with designation' do
    ia = InsightAnalyses.new.increase_recommendation_analysis('2716653')
    expect(ia).to eq('rowset' => { 'xmlns' => 'urn:schemas-microsoft-com:xml-analysis:rowset',
                                   'schema' =>

                                      { 'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                                        'xmlns:saw_sql' => 'urn:saw-sql',
                                        'targetNamespace' => 'urn:schemas-microsoft-com:xml-analysis:rowset',
                                        'complexType' => { 'name' => 'Row', 'sequence' =>
                                           { 'element' => [{ 'name' => 'Column0', 'type' => 'xsd:int',
                                                             'saw_sql:type' => 'integer', 'minOccurs' => '0',
                                                             'maxOccurs' => '1',
                                                             'saw_sql:displayFormula' => 'saw_0',
                                                             'saw_sql:tableHeading' => '',
                                                             'saw_sql:columnHeading' => '0' },
                                                           { 'name' => 'Column1', 'type' => 'xsd:string',
                                                             'saw_sql:type' => 'varchar', 'minOccurs' => '0',
                                                             'maxOccurs' => '1',
                                                             'saw_sql:displayFormula' => 'saw_1',
                                                             'saw_sql:tableHeading' => 'Designation',
                                                             'saw_sql:columnHeading' => 'Designation Name'
                                                          }] }
                                       }
                                      },
                                   'Row' => { 'Column0' => '0', 'Column1' => 'Test Desig (2716653)' }
    })
  end

  it 'fails with unknown desig' do
    # unknown desig
    expect { InsightAnalyses.new.increase_recommendation_analysis('271665T') }.to raise_error(Savon::ExpectationError)
  end

  it 'fails with no desig' do
    # unknown desig
    expect { InsightAnalyses.new.increase_recommendation_analysis('') }.to raise_error(Savon::ExpectationError)
  end
end
