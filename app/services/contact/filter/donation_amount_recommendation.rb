class Contact::Filter::DonationAmountRecommendation < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts_with_recommendation =
      contacts.joins(donor_accounts: :donation_amount_recommendations)
              .where('"donation_amount_recommendations"."suggested_pledge_amount" > '\
                     '"contacts"."pledge_amount" / "contacts"."pledge_frequency"')
    return contacts_with_recommendation if filters[:donation_amount_recommendation] == 'Yes'
    contacts.where.not(id: contacts_with_recommendation.ids)
  end

  def title
    _('Increase Gift Recommendation')
  end

  def parent
    _('Gift Details')
  end

  def type
    'radio'
  end

  def custom_options
    [{ name: _('Yes'), id: 'Yes' }, { name: _('No'), id: 'No' }]
  end
end
