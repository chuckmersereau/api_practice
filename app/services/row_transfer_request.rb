class RowTransferRequest
  class << self
    # clone: sets if Kirby will leave the rows in the master DB.
    # if false, the rows will be deleted from master after the copy
    #
    # safe: sets if Kirby will fail if some of id's exist in the slave table
    # if false, the ids that are already in the slave db will be ignored
    def transfer(table_name, ids, clone: true, safe: false)
      RestClient.post ENV.fetch('KIRBY_URL'), payload(table_name, Array.wrap(ids), clone, safe), headers
      Rails.logger.debug "#{ids.size} records on #{table_name} transferred"
    end

    private

    def payload(table, ids, clone, safe)
      { table: table, uuids: ids.join(','), clone: clone, safe: safe }.to_json
    end

    def headers
      { content_type: :json, 'x-api-key' => ENV.fetch('AWS_API_GATEWAY_KEY') }
    end
  end
end
