module JsonApiService
  class InvalidTypeError                < StandardError; end
  class InvalidPrimaryKeyPlacementError < StandardError; end
  class MissingTypeError                < StandardError; end
  class ForeignKeyPresentError          < StandardError; end
end
