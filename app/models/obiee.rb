require 'savon'

class Obiee

  def auth_client
    client = get_client( true, APP_CONFIG['obiee_base_url'] + '/wsdl/v7' )
    creds = {name: APP_CONFIG['obiee_key'], password: APP_CONFIG['obiee_secret'] }
    auth_message = call( client, :logon, creds)
    auth_message.body[:logon_result][:session_id]
  end

  def report_sql(session_id,path,presentation_var,desig)

    get_report_client = get_client( false, APP_CONFIG['obiee_base_url'] + '?SoapImpl=reportService')
    report_params = { reportRef: {reportPath: path},
                      reportParams: {filterExpressions: '',
                                     variables: {
                                         name: presentation_var,
                                         value: desig
                                     }
                      },
                      sessionID: session_id}
    report_message = call( get_report_client, :generateReportSQL, report_params )
    report_message.body[:generate_report_sql_result][:return]
  end

  def report_results(session_id, report_sql)

    run_report_client = get_client( false, APP_CONFIG['obiee_base_url'] + '?SoapImpl=xmlViewService' )
    run_params = {sql: report_sql,
                  outputFormat: 'SAWRowsetSchemaAndData',
                  executionOptions:
                      {async: '',
                       maxRowsPerPage: -1,
                       refresh: true,
                       presentationInfo: true,
                       type: ''},
                  sessionID: session_id}

    returned_results = call(run_report_client,:executeSQLQuery, run_params)
    #run_report_client.call( :logoff, message: session_id)  for some reason this call returns with the expired/invalid session exception
    returned_results.body[:execute_sql_query_result][:return][:rowset]

  end

  def call(client,operation,params={})
    client.call( operation,message: params)
  end

  def get_client(option, url)

    call_url = Hash.new

    if (option)
      call_url = { wsdl: url }
    else
      call_url = { endpoint: url, namespace: "urn://oracle.bi.webservices/v7"}
    end

    Savon.client(call_url)

  end


end