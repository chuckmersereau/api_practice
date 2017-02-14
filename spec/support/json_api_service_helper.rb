require 'action_controller'

module JsonApiServiceHelpers
  def mock_uuid_reference(from:, to:, resource:)
    uuids = Array[from].flatten
    ids   = Array[to].flatten

    return_values = uuids.map.with_index do |uuid, index|
      id = ids[index]

      [id, uuid]
    end

    return_collection = MockCollection.new(return_values)

    allow(resource)
      .to receive(:where)
      .with(uuid: uuids)
      .and_return(return_collection)
  end

  def build_params_with(hash)
    ActionController::Parameters.new(hash)
  end
end

class MockCollection
  include Enumerable

  attr_reader :values

  def initialize(values)
    @values = values
  end

  def pluck(*)
    values
  end
end

class MockResource
  def self.where(_args); end
end

class MockAccountList < MockResource; end
class MockComment < MockResource; end
class MockContact < MockResource; end
class MockEmail < MockResource; end
class MockPerson < MockResource; end
class MockPerson::FacebookAccount < MockResource; end
class MockTask < MockResource; end
