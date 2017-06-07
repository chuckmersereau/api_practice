class ApplicationPreloader
  class FieldAssociationsFetcher
    attr_reader :field_association_mapping, :serializer_class

    def initialize(field_association_mapping, serializer_class)
      @field_association_mapping = field_association_mapping
      @serializer_class = serializer_class
    end

    def fetch_field_associations(field_params)
      return all_associations unless field_params.present?

      field_association_mapping.map do |field_name, association|
        association if field_params.include?(field_name.to_s)
      end.compact
    end

    private

    def all_associations
      serializer_class._reflections.keys + all_field_associations
    end

    def all_field_associations
      field_association_mapping.values
    end
  end
end
