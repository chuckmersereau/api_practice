module Fields
  class FetchField
    def self.build(model:, type:)
      return_type = type
      GraphQL::Field.define do
        type(return_type)
        description("Find a #{model.name} by ID")
        argument(:id, !types.ID, "ID for Record")
        resolve ->(obj, args, ctx) {
          model.find_by(uuid: args["id"])
        }
      end
    end
  end
end
