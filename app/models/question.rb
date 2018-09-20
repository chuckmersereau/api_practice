class Question < ApplicationRecord
  has_many :weeklies,
           foreign_key: :question_id

  PERMITTED_ATTRIBUTES = [ :id,
                           :question_id,
                           :question,
                           {
                               weeklies_attributes: [
                                   :id,
                                   :answer,
                                   :question_id,
                                   :session_id
                               ]
                           }

  ].freeze
end
