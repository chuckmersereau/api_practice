class DesignationAccountSerializer < ActiveModel::Serializer
  attributes :id, :designation_number, :balance, :name, :created_at, :updated_at
end
