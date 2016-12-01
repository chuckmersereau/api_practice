FactoryGirl.define do
  factory :company_position do
    person nil
    company nil
    start_date '2012-03-09'
    end_date '2012-03-09'
    position 'MyString'
  end
end
