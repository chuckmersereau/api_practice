class Contact::Filter::RelatedTaskAction < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      if filters[:related_task_action].first == 'null'
        contacts_with_activities = contacts.where('activities.completed' => false)
                                           .includes(:activities).map(&:id)
        contacts.where('contacts.id not in (?)', contacts_with_activities)
      else
        contacts.where('activities.activity_type' => filters[:related_task_action])
                .where('activities.completed' => false)
                .includes(:activities)
      end
    end

    def title
      _('Action')
    end

    def parent
      _('Tasks')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      [{ name: _('-- None --'), id: 'null' }] + related_tasks(account_list).collect { |a| { name: _(a), id: a } }
    end

    private

    def related_tasks(account_list)
      Task.new.assignable_activity_types & account_list.tasks.select(:activity_type).uniq.collect(&:activity_type)
    end
  end
end
