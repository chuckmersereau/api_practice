module Mutations
  ContactUpdateMutation = GraphQL::Relay::Mutation.define do
    # Used to name derived types, eg `"AddCommentInput"`:
    name 'ContactUpdate'

    # Accessible from `input` in the resolve function:
    input_field :id, !types.ID
    input_field :name, !types.String

    # The result has access to these fields,
    # resolve must return a hash with these keys
    return_field :contact, Types::ContactType

    # The resolve proc is where you alter the system state.
    resolve -> (object, inputs, ctx) {
      attrs = inputs.to_h
      contact = Contact.find_by(uuid: attrs.delete('id'))
      contact.update(attrs)

      # The keys in this hash correspond to `return_field`s above:
      {
        contact: contact
      }
    }
  end
end
