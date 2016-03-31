class RelayAccountDupTrimmer
  def clean_up_dup_relay
    dup_relay_guids = Person::RelayAccount.group('lower(remote_id)').having('count(*) > 1').count.keys
    accounts_to_del = []
    people_to_del = []
    dup_relay_guids.each do |rguid|
      person_ids = Person::RelayAccount.where('lower(remote_id) = ?', rguid).pluck(:person_id).uniq
      accounts = Person::RelayAccount.where('lower(remote_id) = ?', rguid)
      if person_ids.one?
        keep = accounts.order(updated_at: :desc).first
      else
        keep, people = which_account_to_keep(accounts)
        people_to_del += people
      end
      accounts.each { |a| accounts_to_del << a unless a == keep }
    end

    delete_accounts(accounts_to_del)
    delete_people(people_to_del)
  end

  private

  def delete_accounts(accounts_to_del)
    accounts_to_del.each do |account|
      Person::RelayAccount.transaction do
        PaperTrail::Version.create(item_type: 'Person::RelayAccount', item_id: account.id, event: 'destroy',
                                   object: PaperTrail::Serializers::YAML.dump(account),
                                   related_object_type: 'Person', related_object_id: account.person_id,
                                   whodunnit: 'RelayAccountDupTrimmer')
        account.destroy!
      end
    end
  end

  def delete_people(people)
    # delete all the people if they have no more relay accounts
    people.each do |person|
      next if Person::RelayAccount.where(person: person).any? || Person::KeyAccount.where(person_id: person.id).any?
      Person.transaction do
        PaperTrail::Version.create(item_type: 'Person', item_id: person.id, event: 'destroy',
                                   object: PaperTrail::Serializers::YAML.dump(person),
                                   whodunnit: 'RelayAccountDupTrimmer')
        person.organization_accounts.each do |oa|
          PaperTrail::Version.create(item_type: 'Person::OrganizationAccount', item_id: oa.id, event: 'destroy',
                                     object: PaperTrail::Serializers::YAML.dump(oa),
                                     related_object_type: 'Person', related_object_id: person.id,
                                     whodunnit: 'RelayAccountDupTrimmer')
        end
        person.organization_accounts.delete_all
        person.delete
      end
    end
  end

  def which_account_to_keep(accounts)
    account_sign_ins = accounts.each_with_object({}) do |a, hash|
      hash[a] = a.person.current_sign_in_at
    end
    to_keep = account_sign_ins.max[0]
    people = accounts.collect(&:person).uniq
    people.delete to_keep.person
    [to_keep, people]
  end
end
