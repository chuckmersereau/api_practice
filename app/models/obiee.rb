require 'savon'

class Obiee
  attr_accessor :session_id
  OBIEE_URL = ENV.fetch('OBIEE_BASE_URL')

  def initialize
    creds = { name: ENV.fetch('OBIEE_KEY'), password: ENV.fetch('OBIEE_SECRET') }
    url = OBIEE_URL + 'nQSessionService'
    client = get_client(url)
    auth_message = make_call(client, :logon, creds)
    @session_id = auth_message.body[:logon_result][:session_id]
  end

  def report_results(session_id, report_path, vars = {})
    url = OBIEE_URL + 'xmlViewService'
    run_report_client = get_client(url)
    run_params = { report: { reportPath: report_path },
                   outputFormat: 'SAWRowsetAndData',
                   executionOptions:
                       { async: '',
                         maxRowsPerPage: -1,
                         refresh: true,
                         presentationInfo: true,
                         type: '' },
                   reportParams: { filterExpressions: '',
                                   variables: vars
                   },
                   sessionID: session_id }
    returned_results = make_call(run_report_client, :executeXMLQuery, run_params)
    returned_results.body[:execute_xml_query_result][:return][:rowset]
  end

  private

  def make_call(client, operation, params = {})
    client.call(operation, message: params)
  end

  def get_client(url)
    call_url = { endpoint: url, namespace: 'urn://oracle.bi.webservices/v7',
                 open_timeout: 30, read_timeout: 30, filters: [:password, :session_id] }
    Savon.client(call_url)
  end
end
