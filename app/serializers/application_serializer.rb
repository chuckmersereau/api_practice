class ApplicationSerializer < ActiveModel::Serializer
  attributes :id,
             :created_at,
             :updated_at,
             :updated_in_db_at

  def id
    object.uuid
  end

  def self.collection_serialize(resources)
    ActiveModelSerializers::SerializableResource.new(resources, each_serializer: self)
  end

  def attributes(*args)
    super(*args).transform_values do |value|
      value = value.to_time.utc.iso8601 if value.respond_to?(:iso8601)
      value
    end
  end

  def updated_in_db_at
    object.updated_at
  end
end
