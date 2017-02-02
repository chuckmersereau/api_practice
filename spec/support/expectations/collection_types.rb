require 'rspec/expectations'

RSpec::Matchers.define :be_a_hash_with_types do |key_type, value_type|
  match do |actual|
    actual.is_a?(Hash) && actual.all? do |k, v|
      k.is_a?(key_type) && v.is_a?(value_type)
    end
  end
end
