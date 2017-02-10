module Mutations
  ContactCreateMutation = GraphQL::Relay::Mutation.define do
    # Used to name derived types, eg `"AddCommentInput"`:
    name 'ContactCreate'

    # Accessible from `input` in the resolve function:
    input_field :name, !types.String
    input_field :accountListId, !types.ID

    # The result has access to these fields,
    # resolve must return a hash with these keys
    return_field :contact, Types::ContactType
    return_field :accountList, Types::AccountListType

    # The resolve proc is where you alter the system state.
    resolve -> (object, inputs, ctx) {
      attrs = inputs.to_h
      account_list_uuid = attrs.delete('accountListId')

      account_list = AccountList.find_by!(uuid: account_list_uuid)
      contact = account_list.contacts.create!(attrs)

      # The keys in this hash correspond to `return_field`s above:
      {
        contact: contact,
        accountList: account_list
      }
    }
  end
end
