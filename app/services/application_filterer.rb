class ApplicationFilterer
  attr_accessor :account_lists, :filters, :initial_scope

  FILTERS_TO_DISPLAY = [].freeze

  FILTERS_TO_HIDE = [].freeze

  def initialize(filters = nil)
    @first_filter_queried = false
    @filters = filters || {}
    @filters.map { |k, v| @filters[k] = v.strip if v.is_a?(String) }
  end

  def filter(scope:, account_lists:)
    @initial_scope = scope
    @account_lists = account_lists

    self.class.filter_classes.each do |klass|
      scope = add_to_scope(klass, scope)
    end
    scope
  end

  def self.config(account_lists)
    filter_classes.map do |klass|
      filter = klass.new(account_lists)
      filter if filter.display_filter_option? && !filter.empty?
    end.compact
  end

  def self.filter_classes
    @filter_classes ||= (self::FILTERS_TO_DISPLAY + self::FILTERS_TO_HIDE).sort.map do |class_name|
      prefix = to_s.split('::')[0...-1].join('::')
      "#{prefix}::Filter::#{class_name}".constantize
    end
  end

  def self.filter_params
    @filter_params ||= (self::FILTERS_TO_DISPLAY + self::FILTERS_TO_HIDE).sort.map do |class_name|
      class_name.underscore.to_sym
    end
  end

  private

  def add_to_scope(klass, scope)
    if filters[:any_filter].to_s == 'true'
      scope_to_add = klass.new(account_lists).query(initial_scope, filters)
      return scope unless scope_to_add
      return scope_to_add if scope.to_sql == initial_scope.to_sql
      resource_class.where(id: (scope.ids + scope_to_add.ids).uniq)
    else
      klass.new(account_lists).query(scope, filters) || scope
    end
  end

  def resource_class
    self.class.to_s.split('::').first.constantize
  end
end
