class PartnerStatusLog < ApplicationRecord
  belongs_to :contact

  def pledge_currency
    self[:pledge_currency] || contact.pledge_currency
  end
end
