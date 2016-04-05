class Admin::AccountDupPhonesFix
  def initialize(account_list)
    @account_list = account_list
  end

  def fix
    Person.where(id: person_ids_multi_phones).includes(:phone_numbers)
          .find_each(&method(:clean_dup_person_phones))
  end

  private

  def people_phone_counts
    @account_list.people.joins(:phone_numbers).group('phone_numbers.person_id').count
  end

  def person_ids_multi_phones
    people_phone_counts.select do |_person_id, num_phones|
      num_phones > 1
    end.keys
  end

  def clean_dup_person_phones(person)
    Admin::DupPhonesFix.new(person).fix
  end
end
