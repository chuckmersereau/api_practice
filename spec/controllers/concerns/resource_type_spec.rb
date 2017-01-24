require 'spec_helper'

RSpec.describe ResourceType, type: :concern do
  context 'when a custom resource_type is set' do
    it 'allows the setting of a custom resource_type for a controller' do
      controller = Mock::ControllerForCustomResourceType.new

      expect(controller.resource_type).to eq :mock_resource_type
    end
  end

  context "when a custom resource_type isn't set" do
    it 'pulls the resource type from the controller name' do
      controller = Mock::UsersController.new

      expect(controller.resource_type).to eq :users
    end
  end

  describe '.custom_resource_type' do
    context 'when a resource_type is set' do
      it 'returns the resource_type as a :sym' do
        expect(Mock::ControllerForCustomResourceType.custom_resource_type)
          .to eq(:mock_resource_type)
      end
    end

    context "when a resource_type isn't set" do
      it 'is nil' do
        expect(Mock::UsersController.custom_resource_type).to be_nil
      end
    end
  end
end

module Mock
  class ControllerForCustomResourceType
    include ResourceType

    resource_type :mock_resource_type
  end

  class UsersController
    include ResourceType
  end
end
