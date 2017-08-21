# This service class tries to build a Contact's name in a consistent format.
# Accepts a Hash (a name already parsed and into parts), or a String (needs to be parsed).
# If given a String, it will try to guess if it's not a human name.

class Contact::NameBuilder
  WORDS_THAT_INDICATE_NONHUMAN_NAME = %w(agency alliance assembly baptist bible business calvary
                                         charitable chinese christ church city college community
                                         company construction cornerstone corp corporation evangelical
                                         family fellowship financial foundation friends fund god inc
                                         incorporated insurance international life limited ltd
                                         lutheran management methodist ministry missionary national
                                         org organization presbyterian reformed school service trust
                                         united university).freeze

  def initialize(original_input)
    @original_input = original_input

    if @original_input.is_a?(Hash)
      extract_parts_from_hash(@original_input)
    elsif @original_input.is_a?(String)
      extract_parts_from_hash(HumanNameParser.new(@original_input).parse)
    else
      raise ArgumentError
    end
  end

  def name
    return format_ouput(@original_input) if name_appears_to_be_nonhuman?
    format_ouput(build_name_from_parts)
  end

  private

  def extract_parts_from_hash(hash)
    @first_name         = hash[:first_name]
    @middle_name        = hash[:middle_name]
    @last_name          = hash[:last_name]
    @spouse_first_name  = hash[:spouse_first_name]
    @spouse_middle_name = hash[:spouse_middle_name]
    @spouse_last_name   = hash[:spouse_last_name]
  end

  def build_name_from_parts
    first_name_with_middle        = [@first_name, @middle_name].select(&:present?).join(' ')
    spouse_first_name_with_middle = [@spouse_first_name, @spouse_middle_name].select(&:present?).join(' ')
    first_names                   = [first_name_with_middle, spouse_first_name_with_middle].select(&:present?).join(' and ')
    last_names                    = [@last_name, @spouse_last_name].select(&:present?).uniq.join(' and ')
    [last_names, first_names].select(&:present?).join(', ')
  end

  def format_ouput(output)
    output.squish.titleize.gsub(/\sand\s/i, ' and ')
  end

  def name_appears_to_be_nonhuman?
    # If the name is given in parts (not a String) then we have no choice but to make a name out of the parts.
    # If the name is given as a String we try to check if it's not a human name.
    return false unless @original_input.is_a?(String)

    original_input_parts = @original_input.downcase.gsub(/[^[:word:]]/, ' ').squish.split(' ')

    !(original_input_parts & WORDS_THAT_INDICATE_NONHUMAN_NAME).empty?
  end
end
