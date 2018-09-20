class Weekly < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :id,
                           :answer,
                           :question_id,
  ].freeze

  def message
    @message = "Hello world"
  end


end
