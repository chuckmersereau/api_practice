# Allows exporting of the core data of an acount list to SQL for local
# debugging of user issues.

def save_account_list_sql_to_s3(account_list)
  filename = "account_list_#{account_list.id}_at_#{Time.now.to_i}.sql"
  upload_to_s3(filename, account_list_sql(account_list))
end

def upload_to_s3(filename, body)
  conn = Fog::Storage.new(provider: 'AWS',
                          aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
                          aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'))
  dir = conn.directories.get(ENV.fetch('AWS_BUCKET'))
  path = "debug_exports/#{filename}"
  file = dir.files.new(key: path, body: body)
  file.save
  puts "Saved in #{ENV.fetch('AWS_BUCKET')} bucket at #{path}"
end

def account_list_sql(account_list)
  sql = []
  sql << model_insert_sql(account_list)
  [
    account_list.contacts,
    account_list.people,
    account_list.addresses,
    ContactPerson.where(contact: account_list.contacts),
    PhoneNumber.where(person: account_list.people),
    EmailAddress.where(person: account_list.people)
  ].each do |relation|
    sql += relation_insert_sql(relation)
  end
  sql.join("\n")
end

def relation_insert_sql(relation)
  relation.uniq.map(&method(:model_insert_sql))
end

def model_insert_sql(model)
  quoted_columns = []
  quoted_values = []

  attributes_with_values =
    model.send(:arel_attributes_with_values_for_create, model.attribute_names)

  attributes_with_values.each_pair do |key, value|
    quoted_columns << ActiveRecord::Base.connection.quote_column_name(key.name)
    quoted_values << ActiveRecord::Base.connection.quote(value)
  end

  "INSERT INTO #{model.class.quoted_table_name} (#{quoted_columns.join(', ')}) VALUES (#{quoted_values.join(', ')});\n"
end
