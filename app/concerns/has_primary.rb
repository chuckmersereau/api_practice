module HasPrimary
  extend ActiveSupport::Concern

  included do
    cattr_accessor :primary_scope
    after_commit :ensure_only_one_primary
  end

  private

  def ensure_only_one_primary
    self.class.ensure_only_one_primary?(send(primary_scope), self)
  end

  module ClassMethods
    def ensure_only_one_primary?(parent_object, object)
      rel = to_s.tableize.to_sym
      return unless parent_object.present? && parent_object.send(rel).present?

      if object.respond_to?(:historic)
        parent_object.send(rel).where(historic: true).update_all(primary: false)
        not_historic_where = { historic: false }
        return unless parent_object.send(rel).where(not_historic_where).present?
      else
        not_historic_where = {}
      end

      primaries = parent_object.send(rel).where(primary: true).where(not_historic_where)
      if primaries.blank?
        parent_object.send(rel).where(not_historic_where).last.update_column(:primary, true)
      elsif primaries.length > 1
        if primaries.include?(object)
          (primaries - [object]).map { |e| e.update_column(:primary, false) }
        else
          primaries[0..-2].map { |e| e.update_column(:primary, false) }
        end
      end
    end
  end
end
