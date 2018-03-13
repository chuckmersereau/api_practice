class ApplicationSerializer < ActiveModel::Serializer
  attributes :id,
             :created_at,
             :updated_at,
             :updated_in_db_at

  def self.collection_serialize(resources)
    ActiveModelSerializers::SerializableResource.new(resources, each_serializer: self)
  end

  def attributes(*args)
    attrs = super(*args)

    attrs.keys.sort.each_with_object({}) do |key, hash|
      value = attrs[key]
      value = convert_to_utc_iso8601(value) if value.respond_to?(:utc)
      hash[key] = value
    end
  end

  def updated_in_db_at
    object.updated_at
  end

  private

  def convert_to_utc_iso8601(value)
    value.to_time.utc.iso8601
  end
end
