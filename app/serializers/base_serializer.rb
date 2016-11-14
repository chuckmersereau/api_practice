class BaseSerializer < ActiveModel::Serializer
  def self.collection_serialize(resources)
    ActiveModelSerializers::SerializableResource.new(resources, each_serializer: self)
  end
end
