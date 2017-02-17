class AccountList::ChalklineMails < ActiveModelSerializers::Model
  attr_accessor :account_list

  def initialize(attributes = {})
    super
  end

  def send_later
    account_list.async_send_chalkline_list
  end
end
