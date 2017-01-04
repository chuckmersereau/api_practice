class ApplicationFilterSerializer < ActiveModel::Serializer
  attributes :name, :title, :type, :priority, :parent, :default_selection, :multiple, :options
end
