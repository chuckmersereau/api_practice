class TntImport::GroupTagsLoader
  class << self
    def tags_by_tnt_contact_id(xml)
      return {} unless xml['Group']

      tags_by_contact_id = {}

      groups = Array.wrap(xml['Group']['row']).map do |row|
        { id: row['id'], category: row['Category'],
          description: row['Category'] ? row['Description'].sub("#{row['Category']}\\", '') : row['Description'] }
      end
      groups_by_id = Hash[groups.map { |group| [group[:id], group] }]

      Array.wrap(xml['GroupContact']['row']).each do |row|
        group = groups_by_id[row['GroupID']]
        tags = [group_to_tag(group[:description])]
        tags << group_to_tag(group[:category]) if group[:category]

        tags_list = tags_by_contact_id[row['ContactID']]
        tags_list ||= []
        tags_list += tags
        tags_by_contact_id[row['ContactID']] = tags_list
      end

      tags_by_contact_id
    end

    private

    def group_to_tag(group_name)
      group_name.gsub(/\s|,/, '-')
    end
  end
end
