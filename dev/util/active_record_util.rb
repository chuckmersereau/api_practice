def log_active_record
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

def reconnect
  ActiveRecord::Base.connection.reconnect!
rescue PG::UnableToSend
  ActiveRecord::Base.connection.reconnect!
end
