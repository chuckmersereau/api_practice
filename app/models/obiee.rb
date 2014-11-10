require 'savon'

class Obiee

  def auth_client
    client = get_client( APP_CONFIG['obiee_prod_base_url'] + 'nQSessionService' )
    creds = {name: APP_CONFIG['obiee_key'], password: APP_CONFIG['obiee_secret'] }
    auth_message = make_call( client, :logon, creds)
    auth_message.body[:logon_result][:session_id]
  end

  # Pass in the session id, report path, and has with the variable name and it's value.  A hash is used becasuse a
  # report can have a large number of variables.  the key value pair is name: var_name, value: var_value
  def report_sql(session_id,path,vars={})

    get_report_client = get_client( APP_CONFIG['obiee_prod_base_url'] + 'reportService')
    report_params = { reportRef: {reportPath: path},
                      reportParams: {filterExpressions: '',
                                     variables: vars
                      },
                      sessionID: session_id}
    report_message = make_call( get_report_client, :generateReportSQL, report_params )
    report_message.body[:generate_report_sql_result][:return]
  end

  def report_results(session_id, report_sql)

    run_report_client = get_client( APP_CONFIG['obiee_prod_base_url'] + 'xmlViewService' )
    run_params = {sql: report_sql,
                  outputFormat: 'SAWRowsetSchemaAndData',
                  executionOptions:
                      {async: '',
                       maxRowsPerPage: -1,
                       refresh: true,
                       presentationInfo: true,
                       type: ''},
                  sessionID: session_id}

    returned_results = make_call(run_report_client,:executeSQLQuery, run_params)
    #run_report_client.call( :logoff, message: session_id)  # for some reason this call returns with the expired/invalid session exception
    returned_results.body[:execute_sql_query_result][:return][:rowset]

  end

  def make_call(client,operation,params={})
    client.call( operation,message: params)
  end

  def get_client(url)
    call_url = { endpoint: url, namespace: "urn://oracle.bi.webservices/v7", open_timeout: 30, read_timeout: 30}
    Savon.client(call_url)
  end


end