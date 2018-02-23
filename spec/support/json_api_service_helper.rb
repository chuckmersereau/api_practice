require 'action_controller'

module JsonApiServiceHelpers
  def mock_id_reference(from:, to:, resource:)
    ids = Array[from].flatten
    ids = Array[to].flatten

    return_values = ids.map.with_index do |id, index|
      id = ids[index]

      [id, id]
    end

    return_collection = MockCollection.new(return_values)

    allow(resource)
      .to receive(:where)
      .with(id: ids)
      .and_return(return_collection)
  end

  def mock_empty_id_reference(from:, resource:)
    ids = Array[from].flatten
    return_collection = MockCollection.new([])
    allow(resource)
      .to receive(:where)
      .with(id: ids)
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
  def self.find_by(_args); end
  def self.find_by!(_args); end
end

class MockAccountList < MockResource; end
class MockComment < MockResource; end
class MockAddress < MockResource; end
class MockContact < MockResource; end
class MockEmail < MockResource; end
class MockPerson < MockResource; end
class MockPerson::FacebookAccount < MockResource; end
class MockTask < MockResource
  end
