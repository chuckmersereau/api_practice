class DonorAccountSerializer < ApplicationSerializer
  attributes :account_number,
             :donor_type,
             :first_donation_date,
             :last_donation_date,
             :total_donations,
             :display_name

  belongs_to :organization
  has_many :contacts

  def display_name
    return object.account_number if name.blank?
    return name if object.account_number.blank? || name.include?(object.account_number)
    "#{name} (#{object.account_number})"
  end

  def contacts
    return object.contacts.none unless scope && scope[:account_list]
    object.contacts.where(account_list: scope[:account_list])
  end

  protected

  def name
    return @name if @name
    @name = if scope && scope[:account_list] && object.name
              object.link_to_contact_for(scope[:account_list]).name
            elsif object.name
              object.name
            end
  end
end
