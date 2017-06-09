class Contact::NameBuilder
  def initialize(first_name: nil, last_name: nil, spouse_first_name: nil, spouse_last_name: nil)
    @first_name = first_name
    @last_name = last_name
    @spouse_first_name = spouse_first_name
    @spouse_last_name = spouse_last_name
  end

  def name
    first_names = [@first_name, @spouse_first_name].select(&:present?).to_sentence
    last_names = [@last_name, @spouse_last_name].select(&:present?).uniq.to_sentence
    [last_names, first_names].select(&:present?).join(', ')
  end
end
