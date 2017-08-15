class ContactMerge
  def initialize(winner, loser)
    @winner = winner
    @other = loser
  end

  def merge
    begin
      Contact.find(@winner.id)
      Contact.find(@other.id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    merge_contacts

    delete_losing_contact

    begin
      @winner.reload
    rescue ActiveRecord::RecordNotFound
      return
    end

    fixup_winning_contact
  end

  def self.merged_send_newsletter(winner, other)
    return 'Both' if winner == 'Both' || other == 'Both'
    send_newsletter_word(winner == 'Email' || other == 'Email',
                         winner == 'Physical' || other == 'Physical')
  end

  def self.send_newsletter_word(email, physical)
    if email && physical
      'Both'
    elsif email
      'Email'
    elsif physical
      'Physical'
    end
  end

  private

  def merge_contacts
    Contact.transaction(requires_new: true) do
      # Update related records
      @other.messages.update_all(contact_id: @winner.id)

      @other.contact_people.each do |r|
        next if @winner.contact_people.find_by(person_id: r.person_id)
        r.update_attributes(contact_id: @winner.id)
      end

      @other.contact_donor_accounts.each do |other_contact_donor_account|
        next if @winner.donor_accounts.map(&:account_number).include?(other_contact_donor_account.donor_account.account_number)
        other_contact_donor_account.update_column(:contact_id, @winner.id)
      end

      @other.activity_contacts.each do |other_activity_contact|
        next if @winner.activities.map(&:subject).include?(other_activity_contact.activity.subject)
        other_activity_contact.update_column(:contact_id, @winner.id)
      end
      @winner.update_uncompleted_tasks_count

      @other.addresses.each do |other_address|
        next if @winner.addresses.find { |address| address.equal_to? other_address }
        other_address.update_columns(
          primary_mailing_address: false,
          addressable_id: @winner.id
        )
      end

      @other.notifications.update_all(contact_id: @winner.id)

      @winner.merge_addresses

      ContactReferral.where(referred_to_id: @other.id).find_each do |contact_referral|
        contact_referral.update_column(:referred_to_id, @winner.id) unless @winner.contact_referrals_to_me.find_by(referred_by_id: contact_referral.referred_by_id)
      end

      ContactReferral.where(referred_by_id: @other.id).update_all(referred_by_id: @winner.id)

      # Copy fields over updating any field that's blank on the winner
      Contact::MERGE_COPY_ATTRIBUTES.each do |field|
        next unless @winner[field].blank? && @other[field].present?
        @winner.send("#{field}=".to_sym, @other[field])
      end

      @winner.send_newsletter = self.class.merged_send_newsletter(@winner.send_newsletter,
                                                                  @other.send_newsletter)

      # If one of these is marked as a finanical partner, we want that status
      if @winner.status != 'Partner - Financial' && @other.status == 'Partner - Financial'
        @winner.status = 'Partner - Financial'
      end

      # Make sure first and last donation dates are correct
      if @winner.first_donation_date && @other.first_donation_date && @winner.first_donation_date > @other.first_donation_date
        @winner.first_donation_date = @other.first_donation_date
      end
      if @winner.last_donation_date && @other.last_donation_date && @winner.last_donation_date < @other.last_donation_date
        @winner.last_donation_date = @other.last_donation_date
      end

      @winner.notes = [@winner.notes, @other.notes].compact.join("\n").strip if @other.notes.present?

      @winner.tag_list += @other.tag_list

      @winner.save(validate: false)
    end
  end

  def delete_losing_contact
    @other.reload
    @other.destroy
  rescue ActiveRecord::RecordNotFound
  end

  def fixup_winning_contact
    @winner.merge_people
    @winner.merge_donor_accounts

    # Update donation total after donor account ids are all assigned correctly
    @winner.update_all_donation_totals
  end
end
