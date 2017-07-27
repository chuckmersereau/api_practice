class ApplicationPreloader
  class IncludeAssociationsFetcher
    attr_reader :association_preloader_mapping, :resource_path

    def initialize(association_preloader_mapping, resource_path)
      @association_preloader_mapping = association_preloader_mapping
      @resource_path = resource_path
    end

    def fetch_include_associations(include_params, field_params)
      @include_params = include_params
      @field_params = field_params

      indirect_include_association_parents.inject(direct_include_associations) do |associations, direct_association|
        associations + [indirect_associations_hash(direct_association)]
      end.compact
    end

    private

    def indirect_associations_hash(direct_association)
      indirect_associations = fetch_indirect_associations(direct_association)
      { direct_association.to_sym => indirect_associations } if indirect_associations.present?
    end

    def fetch_indirect_associations(direct_association)
      relevant_include_params = fetch_relevant_include_params(direct_association)

      included_parent_association = direct_include_associations.include?(direct_association.to_sym)

      preloader_class_from_association(direct_association).new(relevant_include_params, @field_params, direct_association)
                                                          .associations_to_preload(included_parent_association)
    rescue NameError
      nil
    end

    def fetch_relevant_include_params(association)
      params = @include_params.select { |param| param.include?('.') && param.split('.').first == association }
      params.map { |param| param.split('.').drop(1).join('.') }
    end

    def preloader_class_from_association(association)
      association_preloader_mapping[association.to_sym] ||
        "::#{resource_path}::#{association.camelize}Preloader".constantize
    end

    def direct_include_associations
      @direct_include_associations ||= @include_params.select { |param| !param.include?('.') }.map(&:to_sym)
    end

    def indirect_include_association_parents
      @indirect_association_parents ||= @include_params.map { |param| param.split('.').first }.uniq
    end
  end
end
