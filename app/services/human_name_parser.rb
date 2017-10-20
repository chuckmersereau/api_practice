# This class attempts to parse a human name contained in a single String into smaller parts (as a Hash).
# The 'nameable' gem helps us do this. The nameable gem does not handle couple names, so we take care of
# splitting a couple name, as well as some other cleanup for couple names.
# Nameable should not need to be referenced outside of this class.
#
# Known limitations:
#   * If a couple has different last names or middle names then it can be hard to differentiate them.
#   * Does not handle non-human names (like businesses).
#   * Not well tested on non-American names.

require 'nameable'

class HumanNameParser
  def initialize(input_name)
    @input_name = input_name
  end

  def parse
    names_hash = build_names_hash
    fill_in_middle_and_last_names_after_parsing(names_hash)
  end

  private

  attr_accessor :input_name

  def build_names_hash
    {
      first_name:         parsed_names.first&.first,
      middle_name:        parsed_names.first&.middle,
      last_name:          parsed_names.first&.last,
      spouse_first_name:  parsed_names.second&.first,
      spouse_middle_name: parsed_names.second&.middle,
      spouse_last_name:   parsed_names.second&.last
    }
  end

  def parsed_names
    @parsed_names ||= names.collect do |name|
      begin
        Nameable.parse(name)
      rescue Nameable::InvalidNameError
        if known_unparsable(name)
          Nameable::Latin.new(first: name)
        else
          notify_rollbar(name)
          Nameable::Latin.new
        end
      end
    end
  end

  def notify_rollbar(name)
    Rollbar.info(UnparsableNameError.new('A parseable name was not found.'),
                 name: name,
                 input_name: input_name)
  end

  # a list (mostly from Rollbar) of the strings that people enter as first names.
  # This will return true if there are an number of these single characters in a row.
  def known_unparsable(name)
    [['.'], ['?'], [':'], ['!'], [',']].include? name.chars.to_a.uniq
  end

  def names
    clean_input_name.split(' and ')
  end

  def clean_input_name
    remove_couple_prefix(
      remove_parenthesis(
        normalize_and(input_name.strip)
      )
    ).strip.squish
  end

  # Remove couple prefixes, like "Mr. and Mrs."
  def remove_couple_prefix(string)
    string.gsub(/\Am(rs|r|s|iss){1}[.]?\s*(and|&)\s*m(rs|r|s|iss){1}[.]?/i, '')
  end

  # Remove parenthesis, which are often used for nicknames or secondary info.
  def remove_parenthesis(string)
    string.gsub(/\([^()]*\)/, '')
          .gsub('()', '')
  end

  def normalize_and(string)
    string.gsub(/\sand\s/i, ' and ').gsub(' & ', ' and ')
  end

  # Try to fixup the middle and last names by comparing the two couples to each other.
  def fill_in_middle_and_last_names_after_parsing(names_hash)
    # This is necessary because often a couple's last name is only present once in the input:
    #   e.g. in "John and Jane Doe" there is no last name given for John.
    # Also, in this situation the last name can become confused with a middle name:
    #   e.g. in "Doe, John and Jane Louise" it looks like Jane's last name is "Louise" but really it's "Doe".
    #
    # We know that there will never be a middle name without a last name at this point
    # (i.e. if a person has a middle name, it's because they also have a last name).

    # If neither person has a middle name, then try to get a last name from whoever has it.
    if names_hash[:middle_name].blank? && names_hash[:spouse_middle_name].blank?
      if names_hash[:last_name].present?
        names_hash[:spouse_middle_name] = names_hash[:spouse_last_name]
        names_hash[:spouse_last_name] = names_hash[:last_name]
      else
        names_hash[:middle_name] = names_hash[:last_name]
        names_hash[:last_name] = names_hash[:spouse_last_name]
      end

    # If only one has a middle name and the last names are different then the real middle name probably went into the last name.
    elsif names_hash[:middle_name].blank? && (names_hash[:last_name] != names_hash[:spouse_last_name])
      names_hash[:middle_name] = names_hash[:last_name]
      names_hash[:last_name] = names_hash[:spouse_last_name]

    elsif names_hash[:spouse_middle_name].blank? && (names_hash[:last_name] != names_hash[:spouse_last_name])
      names_hash[:spouse_middle_name] = names_hash[:spouse_last_name]
      names_hash[:spouse_last_name] = names_hash[:last_name]
    end

    # If there is no first name for the spouse then don't return anything for spouse.
    if names_hash[:spouse_first_name].blank?
      names_hash[:spouse_last_name] = nil
      names_hash[:spouse_middle_name] = nil
    end

    names_hash
  end

  class UnparsableNameError < StandardError; end
end
