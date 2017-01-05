class ApplicationFilterSerializer < ActiveModel::Serializer
  attributes :name, :title, :type, :parent, :default_selection, :multiple, :options
end
