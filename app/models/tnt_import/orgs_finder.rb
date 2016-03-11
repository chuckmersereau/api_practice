class TntImport::OrgsFinder
  class << self
    def orgs_by_tnt_id(parsed_xml, default_org)
      return unless parsed_xml['Organization'].present?
      orgs_by_tnt_id = {}
      Array.wrap(parsed_xml['Organization']['row']).each do |org_row|
        orgs_by_tnt_id[org_row['id']] =
          Organization.find_by(code: org_row['Code']) || default_org
      end
      orgs_by_tnt_id
    end
  end
end
