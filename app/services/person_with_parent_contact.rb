class PersonWithParentContact < ActiveModelSerializers::Model
  attr_accessor :person, :parent_contact

  delegate :anniversary_day,
           :anniversary_month,
           :anniversary_year,
           :birthday_day,
           :birthday_month,
           :birthday_year,
           :created_at,
           :deceased,
           :email_addresses,
           :employer,
           :facebook_accounts,
           :family_relationships,
           :first_name,
           :gender,
           :last_name,
           :legal_first_name,
           :linkedin_accounts,
           :marital_status,
           :middle_name,
           :occupation,
           :optout_enewsletter,
           :phone_numbers,
           :suffix,
           :title,
           :twitter_accounts,
           :updated_at,
           :updated_in_db_at,
           :id,
           :websites,
           to: :person

  def initialize(person:, parent_contact:)
    @person = person
    @parent_contact = parent_contact
  end
end
