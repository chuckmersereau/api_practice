class Question < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :id,
                           :question
  ].freeze
end
