class Weekly < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :answer,
                           :question_id,
                           :sid
  ].freeze


  def serializer_class
    WeeklySerializer
  end


end
