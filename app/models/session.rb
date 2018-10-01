class Session < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :user,
                           :sid
  ].freeze

  before_save :default

  def default
    if Session.maximum("sid") == nil
      self.sid = 1
    else
      self.sid = Session.maximum("sid") +1
    end
  end



end
