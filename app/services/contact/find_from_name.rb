class Contact::FindFromName
  def initialize(contact_scope, name)
    @contact_scope = contact_scope
    @name = name
  end

  def first
    find_contact_by_name.first.presence ||
      find_contact_by_greeting.first.presence ||
      find_contact_by_primary_person.first.presence ||
      find_contact_by_spouse.first.presence
  end

  private

  attr_accessor :name, :contact_scope

  def find_contact_by_name
    contact_scope.where(name: [name, parse_and_rebuild_name].select(&:present?))
  end

  def find_contact_by_greeting
    contact_scope.where(greeting: [name, parse_and_rebuild_name, parse_and_rebuild_first_name].select(&:present?))
  end

  def find_contact_by_primary_person
    contact_scope.people.joins(:people).where(people: { first_name: parsed_name_parts[:first_name], last_name: parsed_name_parts[:last_name] })
  end

  def find_contact_by_spouse
    contact_scope.people.joins(:people).where(people: { first_name: parsed_name_parts[:spouse_first_name], last_name: parsed_name_parts[:spouse_last_name] })
  end

  def parsed_name_parts
    @parsed_name_parts ||= HumanNameParser.new(name).parse
  end

  def parse_and_rebuild_name
    @parse_and_rebuild_name ||= Contact::NameBuilder.new(name).name
  end

  def parse_and_rebuild_first_name
    @parse_and_rebuild_first_name ||= Contact::NameBuilder.new(parsed_name_parts.slice(:first_name, :spouse_first_name)).name
  end
end
