class ContactDetailSerializer < ContactSerializer
  attribute :lifetime_donations

  def lifetime_donations
    object.donations.sum(:amount)
  end
end
