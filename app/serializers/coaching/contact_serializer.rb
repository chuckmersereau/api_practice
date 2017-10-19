class Coaching::ContactSerializer < ApplicationSerializer
  attributes :late_at,
             :locale,
             :name,
             :pledge_amount,
             :pledge_currency,
             :pledge_currency_symbol,
             :pledge_frequency,
             :pledge_received,
             :pledge_start_date

  delegate :total,
           to: :contact_exhibit

  def contact_exhibit
    @exhibit ||= Coaching::ContactExhibit.new(object, nil)
  end
end
