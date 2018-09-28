class Question < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :id,
                           :question_id,
                           :question
  ].freeze
end
