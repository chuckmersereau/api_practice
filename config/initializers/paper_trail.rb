class Version < ActiveRecord::Base
  #attr_accessible :related_object_type, :related_object_id
  PaperTrail.config.track_associations = false
end

