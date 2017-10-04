class CoachedPersonSerializer < PersonSerializer
  class CoachedPersonExhibit < PersonExhibit
    def self.applicable_to?(object)
      object.class.name == 'User'
    end
  end

  def person_exhibit
    @exhibit ||= CoachedPersonExhibit.new(object, nil)
  end
end
