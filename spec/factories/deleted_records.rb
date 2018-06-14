FactoryGirl.define do
  factory :deleted_record do
    deleted_at Date.current - 1.day
    account_list { |a| a.association(:account_list) }
    deleted_by { |a| a.association(:person) }
    deletable { |a| a.association(:contact) }
  end

  factory :deleted_task_record, parent: :deleted_record do
    deleted_at Date.current - 1.day
    account_list { |a| a.association(:account_list) }
    deleted_by { |a| a.association(:person) }
    deletable { |a| a.association(:task) }
  end
end
