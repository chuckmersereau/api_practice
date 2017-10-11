class ApplicationFilter
  include ActiveModel::Serialization

  attr_reader :account_lists

  def initialize(account_lists = nil)
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

  def self.query(scope, filters, account_list)
    new(account_list).query(scope, filters)
  end

  def query(scope, filters)
    filters[name] ||= default_selection if default_selection.present?

    return unless valid_filters?(filters)
    return scope.where.not(id: execute_query(scope, filters).ids.uniq) if filters["reverse_#{name}".to_sym].to_s == 'true'
    execute_query(scope, filters).distinct
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
    "#{class_name.split('::')[0...-2].join('::')}::Filterer".constantize
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
    raise NotImplementedError, 'You must add a title for this filter'
  end

  def type
    nil
  end

  def execute_query(_contacts, _filters)
  end

  def name
    class_name.demodulize.underscore.to_sym
  end

  def class_name
    self.class.name
  end

  alias id priority

  private

  def fetch_beginning_of_end_month_from_date_range(date_range)
    return date_range.last.beginning_of_month unless date_range_in_same_month?(date_range)

    date_range.last.end_of_month
  end

  def date_range_in_same_month?(date_range)
    date_range.first.month == date_range.last.month
  end

  def daterange_params(date_range)
    { start: date_range.first.beginning_of_day,
      end: date_range.last.end_of_day }
  end

  def parse_list(string)
    string.split(',').select(&:present?).map(&:strip)
  end

  def cast_bool_value(string)
    ActiveRecord::Type::Boolean.new.type_cast_from_user(string)
  end

  def valid_filters?(filters)
    return false unless filters[name].present?
    return false if filters[name].is_a?(Array)
    return false if filters[name].is_a?(Hash)
    true
  end
end
