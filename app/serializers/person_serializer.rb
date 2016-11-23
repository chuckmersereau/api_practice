class PersonSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper

  attributes :anniversary_day,
             :anniversary_month,
             :anniversary_year,
             :avatar,
             :birthday_day,
             :birthday_month,
             :birthday_year,
             :deceased,
             :first_name,
             :gender,
             :last_name,
             :marital_status,
             :master_person_id,
             :middle_name,
             :suffix,
             :title

  has_many :email_addresses
  has_many :facebook_accounts
  has_many :phone_numbers

  def avatar
    person_exhibit.avatar(:large)
  end

  def person_exhibit
    exhibit(object)
  end
end
