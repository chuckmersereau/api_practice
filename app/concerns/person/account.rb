module Person::Account
  extend ActiveSupport::Concern

  included do
    belongs_to :person
    belongs_to :user, foreign_key: :person_id

    scope :authenticated, -> { where(authenticated: true) }
  end

  module ClassMethods
    def find_or_create_from_auth(_auth_hash, _person)
      message = <<~HEREDOC
        `.find_or_create_from_auth` must be defined on #{self} instead of through inheritance from Person::Account.

        In order to work correctly, it must also pass:
          - The person object
          - A hash of attributes for the account
          - A relation scope in which to look for and create the account, ie: `person.key_accounts`

        to `.find_or_create_person_account` in order to return the created account.

        Example:

        def self.find_or_create_from_auth(auth_hash, person)
          # ...
          # pull needed arguments from auth_hash and person
          # ...

          find_or_create_person_account(
            person: person,
            attributes: attributes,
            relation_scope: relation_scope
          )
        end

      HEREDOC

      raise NotImplementedError, message
    end

    def find_related_account(rel, attributes)
      rel.authenticated.find_by(remote_id: attributes[:remote_id])
    end

    def create_user_from_auth(attributes)
      attributes ||= {}
      User.create!(attributes)
    end

    def find_authenticated_user(auth_hash)
      User.find_by(id: authenticated.where(remote_id: auth_hash.uid).pluck(:person_id).first)
    end

    def one_per_user?
      true
    end

    def queue
      :import
    end

    private

    def find_or_create_person_account(person:, attributes:, relation_scope:)
      attributes[:authenticated] = true

      remote_id = attributes[:remote_id]
      account   = find_related_account(relation_scope, attributes)

      if account
        account.update_attributes(attributes)
      elsif other_account = find_by(remote_id: remote_id, authenticated: true)
        # if creating this authentication record is a duplicate, we have a duplicate person to merge
        other_account.update_attributes(person_id: person.id)
        account = other_account
      else
        account = relation_scope.create!(attributes)
      end

      person.first_name = attributes[:first_name] if person.first_name.blank?
      person.last_name  = attributes[:last_name]  if person.last_name.blank?
      person.email      = attributes[:email]      if person.email.blank?

      # start a data import in the background
      account.queue_import_data if account.respond_to?(:queue_import_data)

      account
    end
  end

  class NoSessionError < StandardError
  end
end
