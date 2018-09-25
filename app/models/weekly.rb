class Weekly < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :id,
                           :answer,
                           :question_id,
                           :session_id
  ].freeze

  def message
    @message = "Hello world"
  end

  @@session_num = 0
  def self.session_num
    @@session_num
  end


end
