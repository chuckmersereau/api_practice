class Constants::OrganizationList
  alias read_attribute_for_serialization send

  def organizations
    @organizations ||= organizations_hash
  end

  def id
  end

  private

  def organizations_hash
    Hash[
      Organization.active.all.map { |org| [org.id, org] }
    ]
  end
end
