# https://github.com/rails/rails/pull/23666
# This PR was never backported to 4.2-stable and is needed to use default_scope on an abstract class
# can
module ActiveRecord
  module Scoping
    module Default
      module ClassMethods
        protected

        def build_default_scope(base_rel = relation) # :nodoc:
          return if abstract_class?
          if !Base.is_a?(method(:default_scope).owner)
            # The user has defined their own default scope method, so call that
            evaluate_default_scope { default_scope }
          elsif default_scopes.any?
            evaluate_default_scope do
              default_scopes.inject(base_rel) do |default_scope, scope|
                scope = scope.respond_to?(:to_proc) ? scope : scope.method(:call)
                default_scope.merge(base_rel.instance_exec(&scope))
              end
            end
          end
        end
      end
    end
  end
end
