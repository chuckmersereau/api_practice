require 'savon'

class Obiee

  def auth_client
    client = Savon::Client.new(wsdl: "http://plobia08.ccci.org:9704/analytics-ws/saw.dll/wsdl/v7")
    creds = {name: APP_CONFIG['obiee_key'], password: APP_CONFIG['obiee_secret'] }
    auth_message = client.call( :logon,message: creds)
    auth_message.body[:logon_result][:session_id]
  end

  def report_sql(session_id,path,presentation_var,desig)

    get_report_client = get_client("http://plobia08.ccci.org:9704/analytics-ws/saw.dll?SoapImpl=reportService")
    report_params = { reportRef: {reportPath: path},
                      reportParams: {filterExpressions: '',
                                     variables: {
                                         name: presentation_var,
                                         value: desig
                                     }
                      },
                      sessionID: session_id}

    report_message = get_report_client.call( :generateReportSQL, message: report_params )
    report_message.body[:generate_report_sql_result][:return]
  end

  def report_results(session_id, report_sql)

    run_report_client = get_client("http://plobia08.ccci.org:9704/analytics-ws/saw.dll?SoapImpl=xmlViewService")
    run_params = {sql: report_sql,
                  outputFormat: 'SAWRowsetSchemaAndData',
                  executionOptions:
                      {async: '',
                       maxRowsPerPage: -1,
                       refresh: true,
                       presentationInfo: true,
                       type: ''},
                  sessionID: session_id}

    returned_results = run_report_client.call(:executeSQLQuery, message: run_params)
    #run_report_client.call( :logoff, message: session_id)  for some reason this call returns with the expired/invalid session exception
    returned_results.body[:execute_sql_query_result][:return][:rowset]

  end

  def get_client(url)

  Savon.client do
      endpoint url
      namespace "urn://oracle.bi.webservices/v7"
    end

  end


end