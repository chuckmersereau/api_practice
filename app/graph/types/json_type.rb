module Types
  JsonType = GraphQL::ScalarType.define do
    name "JSON"
    description "A JSON encoded string"

    coerce_input ->(value) { JSON.parse(value) }
    coerce_result ->(value) { value.to_json }
  end
end
