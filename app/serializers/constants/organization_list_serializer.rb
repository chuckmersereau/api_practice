class Constants::OrganizationListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  type :organization_list
  attributes :organizations

  def organizations
    organizations_exhibit.organizations.map do |id, organization|
      [organization.name, id]
    end.sort_by(&:first)
  end

  def organizations_exhibit
    @organizations_exhibit ||= exhibit(object)
  end
end
