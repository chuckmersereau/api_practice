FactoryGirl.define do
  factory :task do
    association :account_list
    starred false
    location 'MyString'
    subject { "#{activity_type} #{Faker::Name.name}" }
    start_at '2012-03-08 14:59:46'
    activity_type 'Call'
    result nil
    completed_at nil

    trait :complete do
      completed true
      completed_at { Time.current }
    end

    trait :incomplete do
      completed false
    end

    trait :overdue do
      incomplete
      yesterday
    end

    trait :today do
      start_at { Time.current.beginning_of_day }
    end

    trait :tomorrow do
      start_at { (Date.current + 1.day).beginning_of_day }
    end

    trait :yesterday do
      start_at { (Time.current - 1.day).end_of_day }
    end

    Task::TASK_ACTIVITIES.each do |activity_type|
      trait_type = activity_type.parameterize.underscore.to_sym

      trait trait_type do
        activity_type activity_type
      end
    end

    trait :no_type do
      activity_type nil
    end
  end
end
