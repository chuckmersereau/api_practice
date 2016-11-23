class ApplicationSerializer < ActiveModel::Serializer
  attributes :id,
             :created_at,
             :updated_at

  def self.collection_serialize(resources)
    ActiveModelSerializers::SerializableResource.new(resources, each_serializer: self)
  end
end
