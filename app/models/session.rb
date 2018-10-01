class Session < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :user,
                           :sid
  ].freeze
end
