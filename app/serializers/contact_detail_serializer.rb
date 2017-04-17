class ContactDetailSerializer < ContactSerializer
  attribute :lifetime_donations

  def lifetime_donations
    object.total_donations_query
  end
end
