module ParamsFilters
  extend ActiveSupport::Concern

  included do
	  before_action :load_parent_object

	  attr_accessor :parent_object, :current_account_list, :current_appeal, :current_task

    def load_parent_object
      @parent_object = nil

      params_keys.each do |key|
      	value = params[key.to_sym]
      	get_account_list(value) if key == 'account_list_id'
        get_appeal(value) if key == 'appeal_id'
        get_task(value) if key == 'task_id'
      end

      @parent_object
    end
  end

  def get_account_list(value)
  	@parent_object = AccountList.find(value)
  	@current_account_list = @parent_object
  end

  def get_appeal(value)
  	@parent_object = @parent_object.appeals.find(value)
  	@current_appeal = @parent_object
  end

  def get_task(value)
  	@parent_object = @parent_object.tasks.find(value)
  	@current_task = @parent_object
  end
end
