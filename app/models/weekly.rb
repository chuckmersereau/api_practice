class Weekly < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :id,
                           :answer,
                           :question_id,
                           :session_id
  ].freeze

  # def session_id=(x)
  #   @session_id = x
  #   @session_id = Weekly.maximum(:session_id) + 1
  #   self.session_id = @session_id
  # end

end
