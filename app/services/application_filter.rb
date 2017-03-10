class ApplicationFilter
  include ActiveModel::Serialization

  attr_reader :account_lists

  def initialize(account_lists)
    @account_lists = account_lists
  end

  def self.config(account_lists)
    filter = new(account_lists)
    {
      name: filter.name,
      title: filter.title,
      type: filter.type,
      priority: filter.priority,
      parent: filter.parent,
      default_selection: filter.default_selection
    }.merge(filter.select_options) if filter.display_filter_option? && !filter.empty?
  end

  def self.query(resource, filters, account_list)
    new(account_list).query(resource, filters)
  end

  def query(resource, filters)
    filters[name] ||= default_selection if default_selection.present?
    return unless valid_filters?(filters)
    execute_query(resource, filters)
  end

  def select_options
    return {
      multiple: %w(checkbox multiselect).include?(type),
      options: options
    } if custom_options?
    {}
  end

  def display_filter_option?
    filterer::FILTERS_TO_DISPLAY.index(class_name.demodulize).present?
  end

  def empty?
    custom_options? ? custom_options.empty? : false
  end

  def multiple
    %w(checkbox multiselect).include?(type)
  end

  def options
    default_options + custom_options
  end

  def filterer
    "#{class_name.split('::').first}::Filterer".constantize
  end

  def custom_options?
    %w(radio dropdown checkbox multiselect dates daterange text).include?(type)
  end

  def priority
    filterer::FILTERS_TO_DISPLAY.index(class_name.demodulize) || 100
  end

  def parent
  end

  def default_options
    return [] if %w(text dates daterange).include?(type)
    [{ name: _('-- Any --'), id: '', placeholder: _('None') }]
  end

  def default_selection
    return true if type == 'single_checkbox'
    ''
  end

  def custom_options
    []
  end

  def title
    nil
  end

  def type
    nil
  end

  def execute_query(_contacts, _filters)
  end

  def valid_filters?(filters)
    return false unless filters[name].present?
    return false if filters[name].is_a?(Array)
    return false if filters[name].is_a?(Hash)
    true
  end

  def name
    class_name.demodulize.underscore.to_sym
  end

  def daterange_params(string)
    return {} unless string.is_a?(String) && string.include?(' - ')
    split = string.split(' - ')
    { start: parse_date(split.first).beginning_of_day,
      end: parse_date(split.last).end_of_day }
  end

  def parse_date(string)
    Date.strptime(string, '%m/%d/%Y')
  end

  def class_name
    self.class.name
  end

  alias id priority
end
