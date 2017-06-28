# This class attempts to parse a human name contained in a single String from user input into smaller parts.
# The 'nameable' gem helps us do this. This gem does not handle couple names, so we take care of that here.

require 'nameable'

class HumanNameParser
  def initialize(name)
    @name = name
  end

  def parse
    names = build_names_hash

    names[:spouse_last_name] ||= names[:last_name]
    names[:last_name] ||= names[:spouse_last_name]

    names[:spouse_last_name] = nil if names[:spouse_first_name].blank?

    names
  end

  private

  def build_names_hash
    {
      first_name: parsed_names.first&.first,
      last_name: parsed_names.first&.last,
      spouse_first_name: parsed_names.second&.first,
      spouse_last_name: parsed_names.second&.last
    }
  end

  def parsed_names
    @parsed_names ||= split_couple_name.collect do |name|
      Nameable.parse(name)
    end
  end

  def clean_name
    @name.strip
         .gsub(/\AM(rs|r|s|iss){1}[.]?\s*(and|&)\s*M(rs|r|s|iss){1}[.]?/i, '') # Remove a couple prefix, like "Mr. and Mrs."
         .strip
  end

  def split_couple_name
    clean_name.gsub(' & ', ' and ').split(' and ')
  end
end
