class TntImport::ContactTagsLoader
  def initialize(xml)
    @xml = xml
  end

  def tags_by_tnt_contact_id
    return {} if @xml&.tables&.dig('Contact').blank?

    tags_grouped_by_id = {}

    @xml.tables['Contact'].each do |row|
      tags_grouped_by_id[row['id']] = extract_userfield_tags_from_contact_row(row)
    end

    tags_grouped_by_id
  end

  private

  # Convert User Fields into tags. User Fields are custom fields inside TNT, they consist of a custom label and a custom value.
  # Version 3.2 supports up to 8 User Fields: User1, User2, User3, etc.
  def extract_userfield_tags_from_contact_row(row)
    userfield_labels_and_values = (1..8).collect do |number|
      [display_label_for_userfield_number(number), row["User#{number}"]]
    end
    userfield_labels_and_values.reject! { |label_and_value| label_and_value[1].blank? }
    userfield_labels_and_values.collect { |label_and_value| label_and_value.select(&:present?).join(' - ') }
  end

  def display_label_for_userfield_number(number)
    return unless @xml.tables['Property']

    @xml.tables['Property'].detect do |property|
      property['PropName'] == "User#{number}DisplayLabel"
    end&.[]('PropValue')
  end
end
