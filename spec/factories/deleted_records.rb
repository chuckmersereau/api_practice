FactoryBot.define do
  factory :deleted_record do
    deleted_at Date.current - 1.day
    deleted_from { |a| a.association(:account_list) }
    deleted_by { |a| a.association(:person) }
    deletable { |a| a.association(:contact) }
  end

  factory :deleted_task_record, parent: :deleted_record do
    deleted_at Date.current - 1.day
    deleted_from { |a| a.association(:account_list) }
    deleted_by { |a| a.association(:person) }
    deletable { |a| a.association(:task) }
  end

  factory :deleted_donation_record, parent: :deleted_record do
    deleted_at Date.current
    deleted_from { |a| a.association(:designation_account) }
    deleted_by { |a| a.association(:person) }
    deletable { |a| a.association(:donation) }
  end
end
