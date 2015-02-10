class DataServerPtc < DataServer
  protected

  def profile_balance(profile_code)
    balance = {}
    response = Retryable.retryable on: Errors::UrlChanged, times: 1, then: update_url(:account_balance_url) do
      get_response(@org.account_balance_url,
                   get_params(@org.account_balance_params,  profile: profile_code.to_s))
    end

    # This csv should always only have one line (besides the headers)
    begin
      CSV.new(response, headers: :first_row).each do |line|
        balance[:designation_numbers] = line['EMPLID'].split(',').map { |e| e.gsub('"', '') } if line['EMPLID']
        balance[:account_names] = line['ACCT_NAME'].split('\n') if line['ACCT_NAME']
        balance_match = line['BALANCE'].gsub(',', '').match(/([-]?\d+\.?\d*)/)
        balance[:balance] = balance_match[0] if balance_match
        balance[:date] = line['EFFDT'] ? DateTime.strptime(line['EFFDT'], '%m/%d/%y %H:%M:%S') : Time.now

        break
      end
    rescue NoMethodError
      raise response.inspect
    end
    balance
  end
end