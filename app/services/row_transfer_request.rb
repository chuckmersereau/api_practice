class RowTransferRequest
  class << self
    # clone: sets if Kirby will leave the rows in the master DB.
    # if false, the rows will be deleted from master after the copy
    #
    # safe: sets if Kirby will fail if some of id's exist in the slave table
    # if false, the ids that are already in the slave db will be ignored
    def transfer(klass, ids, clone: true, safe: true)
      table = klass.is_a?(Class) ? klass.table_name : klass

      url = ENV.fetch('KIRBY_URL')
      RestClient.post url, payload(table, Array.wrap(ids), clone, safe), headers
    end

    private

    def payload(table, ids, clone, safe)
      { table: table, ids: ids.join(','), clone: clone, safe: safe }.to_json
    end

    def headers
      { content_type: :json, 'x-api-key' => ENV.fetch('AWS_API_GATEWAY_KEY') }
    end
  end
end
