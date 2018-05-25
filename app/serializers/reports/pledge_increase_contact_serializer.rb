class Reports::PledgeIncreaseContactSerializer < ServiceSerializer
  SERVICE_ATTRIBUTES = [:beginning_monthly, :beginning_currency, :end_monthly, :end_currency, :increase_amount].freeze
  attributes(*SERVICE_ATTRIBUTES)
  delegate(*SERVICE_ATTRIBUTES, to: :object)

  belongs_to :contact
  delegate(:contact, to: :object)
end
