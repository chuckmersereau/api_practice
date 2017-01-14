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
      value = convert_to_utc_iso8601(value) if value.respond_to?(:utc)
      value
    end
  end

  def updated_in_db_at
    object.updated_at.to_s
  end

  private

  def convert_to_utc_iso8601(value)
    value.to_time.utc.iso8601
  end
end
