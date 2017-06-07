# Preloaders allow you to dynamically preload the necessary associations
# to avoid N+1 queries on a client request. Preloader files will be used to
# determine what associations should be preloaded for a given resource.

# To add a preloader, simply create a class that inherits from ApplicationPreloader.
# It will be assumed that the preloader path structure follows that of the controllers.
# For example, the CommentPreloader will only work if it is under the Api::V2::Tasks namespace.

# Eg.

# class Api::V2::TasksPreloader < ApplicationPreloader
#   ASSOCIATION_PRELOADER_MAPPING = {
#     account_list: Api::V2::AccountListsPreloader,
#   }.freeze

#   FIELD_ASSOCIATION_MAPPING = { tag_list: :tags }.freeze
#
# private
#
#   def serializer_class
#     TaskSerializer
#   end
# end

# 'ASSOCIATION_PRELOADER_MAPPING' expects a hash where associations are mapping to
# their corresponding preloader classes.

# 'FIELD_ASSOCIATION_MAPPING' expects a hash where dynamic fields are mapping to
# associations that will need to be loaded when the field method is called.

# 'serializer_class' can optionally be defined to overwrite the ApplicationPreloader
# method which will try to infer the serializer based on the preloader class' name.

# Once the preloader is defined, call it llike this from the controller:
#
# Api::V2::TasksPreloader.new(include_params, field_params).preload(@tasks)
#
# Where 'include_params' and 'field_params' are the controller defined client provided
# parameters and '@tasks' is the Task collection object for which the associations are
# to be preloaded.

class ApplicationPreloader
  attr_reader :include_params, :field_params, :parent_association

  def initialize(include_params, field_params, parent_association = nil)
    @include_params = include_params
    @field_params = field_params
    @parent_association = parent_association || fetch_parent_association
  end

  def preload(collection)
    collection.preload_valid_associations(associations_to_preload)
  end

  def associations_to_preload(add_field_associations = true)
    associations_to_preload = fetch_necessary_include_associations
    associations_to_preload += fetch_necessary_field_associations if add_field_associations
    associations_to_preload.uniq
  end

  private

  def fetch_necessary_include_associations
    IncludeAssociationsFetcher.new(self.class::ASSOCIATION_PRELOADER_MAPPING, resource_path)
                              .fetch_include_associations(include_params, field_params)
  end

  def fetch_necessary_field_associations
    FieldAssociationsFetcher.new(self.class::FIELD_ASSOCIATION_MAPPING, serializer_class)
                            .fetch_field_associations(field_params[parent_association.to_sym])
  end

  def fetch_parent_association
    resource_name.pluralize.underscore.to_sym
  end

  def resource_path
    self.class.to_s.chomp('Preloader')
  end

  def resource_name
    resource_path.split('::').last.singularize
  end

  def serializer_class
    "#{resource_name}Serializer".constantize
  end
end
