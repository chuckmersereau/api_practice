class Weekly < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :id,
                           :answer,
                           :question_id,
                           :session_id
  ].freeze

  def message
    @message = "Hello world"
  end


end
