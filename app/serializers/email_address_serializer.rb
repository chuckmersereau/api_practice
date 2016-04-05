class EmailAddressSerializer < ActiveModel::Serializer
  embed :ids, include: true
  ATTRIBUTES = [:id, :email, :historic, :primary, :created_at, :updated_at].freeze
  attributes(*ATTRIBUTES)
end
