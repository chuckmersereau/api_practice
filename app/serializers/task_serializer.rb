class TaskSerializer < ActiveModel::Serializer
  attributes :id, :account_list_id, :starred, :subject, :created_at, :updated_at, :completed,
             :completed_at, :activity_type, :tag_list, :result, :next_action, :no_date
  attribute :contact_ids, key: :contacts
  attribute :activity_comments_count, key: :comments_count
  attribute :start_at, key: :due_date

  has_many :activity_comments, key: :comments, root: :comments
  has_many :people

  def attributes(arg)
    hash = super(arg)

    if scope.is_a?(Hash) && scope[:since]
      hash[:deleted_comments] = Version.where(item_type: 'ActivityComment', event: 'destroy', related_object_type: 'Activity', related_object_id: id)
                                       .where('created_at > ?', Time.at(scope[:since].to_i)).pluck(:item_id)
    end
    hash
  end

  [:comments].each do |relationship|
    define_method(relationship) do
      add_since(object.send(relationship))
    end
  end
end
