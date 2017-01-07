require 'spec_helper'

describe OrganizationListExhibit do
  let(:context) { double }
  let(:exhibit) { OrganizationListExhibit.new(organization_list, context) }
  let(:organization_list) { Constants::OrganizationList.new }

  context '.applicable_to?' do
    it 'applies only to OrganizationList and not other stuff' do
      expect(OrganizationListExhibit.applicable_to?(Constants::OrganizationList.new)).to be true
      expect(OrganizationListExhibit.applicable_to?(Address.new)).to be false
    end
  end
end
