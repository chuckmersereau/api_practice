class TntImport::GroupTagsLoader
  class << self
    def tags_by_tnt_contact_id(xml)
      return {} unless xml&.tables&.dig('Group').present?

      groups = xml.tables['Group'].map do |row|
        {
          id: row['id'],
          tags: extract_tags_from_group_row(row, xml.version)
        }
      end
      groups_by_id = Hash[
        groups.map { |group| [group[:id], group] }.to_a # force array from Enumerable::Lazy
      ]

      tags_by_contact_id = {}

      xml.tables['GroupContact'].each do |row|
        group = groups_by_id[row['GroupID']]

        tags_by_contact_id[row['ContactID']] ||= []
        tags_by_contact_id[row['ContactID']] += group[:tags]
        tags_by_contact_id[row['ContactID']].uniq!
      end

      tags_by_contact_id
    end

    private

    def group_to_tag(group_name)
      return unless group_name
      group_name
        .gsub(/\s|,/, '-')  # Substitute whitespace and commas with dashes
        .gsub(/-{2,}/, '-') # Substitute multiple adjacent dashes with a single dash
    end

    def extract_tags_from_group_row(row, version)
      return extract_tags_from_group_row_version_3_2(row) if version >= 3.2
      extract_tags_from_group_row_version_3_1(row)
    end

    # TNT Version 3.2:
    # The Category and Description are replaced by PathName.
    # PathName looks like "a\hierarchy\of\tags\separated\by\slashes".
    # We want tag list like:
    # a
    # a\hierarchy
    # a\hierarchy\of
    # a\hierarchy\of\tags
    # a\hierarchy\of\tags\separated
    # a\hierarchy\of\tags\separated\by
    # a\hierarchy\of\tags\separated\by\slashes
    def extract_tags_from_group_row_version_3_2(row)
      groups = row['PathName'].split('\\')
      (1..groups.size).map do |i|
        group_to_tag(groups.first(i).join('\\'))
      end
    end

    # TNT Version 3.1:
    # If a group has a Category, then the Description will look like "category\description".
    # If not, then the Description will just look like "description".
    # We want a tag list like: "category description"
    def extract_tags_from_group_row_version_3_1(row)
      description_tag = row['Description']
      description_tag = description_tag.sub("#{row['Category']}\\", '') if row['Category'].present?
      [description_tag, row['Category']].select(&:present?).map do |group|
        group_to_tag(group)
      end
    end
  end
end
