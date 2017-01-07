class OrganizationListExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'Constants::OrganizationList'
  end
end
