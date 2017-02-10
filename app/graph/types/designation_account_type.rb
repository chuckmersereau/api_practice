module Types
  DesignationAccountType = GraphQL::ObjectType.define do
    name 'DesignationAccount'
    description 'A Designation Account object'

    field :id, !types.ID, 'The UUID of the Designation Account', property: :uuid
    field :active, types.Boolean, 'Whether or not the Designation Account is active'
    field :balance, types.Float, 'The balance in the Designation Account'
    field :balanceUpdatedAt, types.String, "The datetime of when the Designation Account's balance was last updated", property: :balance_updated_at
    field :convertedBalance, types.String, 'The converted balance of the Designation Account' do
      resolve -> (obj, args, ctx) {
        DesignationAccountSerializer.new(obj).currency_symbol
      }
    end
    field :createdAt, !types.String, 'When the Designation Account was created', property: :created_at
    field :currency, types.String, 'The currency of the Designation Account'
    field :currencySymbol, types.String, 'description' do
      resolve -> (obj, args, ctx) {
        DesignationAccountSerializer.new(obj).currency_symbol
      }
    end
    field :designationNumber, types.String, 'TODO', property: :designation_number
    field :exchangeRate, types.String, 'The exchange rate of the Designation Account' do
      resolve -> (obj, args, ctx) {
        DesignationAccountSerializer.new(obj).exchange_rate
      }
    end
    field :name, types.String, 'The name of the Designation Account'
    field :organizationName, types.String, "The name of the Designation Account's Organization" do
      resolve -> (obj, args, ctx) {
        DesignationAccountSerializer.new(obj).organization_name
      }
    end
    field :updatedAt, !types.String, 'The datetime in which the Designation Account was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Designation Account was last updated in the database', property: :updated_at
  end
end
