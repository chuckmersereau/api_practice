class Api::V1::ConstantsController < Api::V1::BaseController
  AVAILABLE_CONSTANTS = %w(assignable_send_newsletters assignable_statuses pledge_frequencies
                           pledge_currencies actions next_actions results bulk_update_options
                           assignable_locations).freeze

  def index
    include_constants = params[:include].present? ? params[:include] : []
    exclude_constants = params[:exclude].present? ? params[:exclude] : []
    constants = load_constants(include_constants, exclude_constants)
    render json: constants.to_json
  end

  protected

  def load_constants(include_constants = [], exclude_constants = [])
    result = {}
    if include_constants.empty?
      (AVAILABLE_CONSTANTS - exclude_constants).map { |key| result[key] = send(key) }
    else
      (AVAILABLE_CONSTANTS & include_constants).map { |key| result[key] = send(key) }
    end
    result
  end

  def assignable_send_newsletters
    Contact.new.assignable_send_newsletters.collect { |s| [s, s] }
  end

  def assignable_statuses
    Contact.new.assignable_statuses.collect { |s| [s, s] }
  end

  def pledge_frequencies
    Contact.pledge_frequencies.invert.to_a
  end

  def pledge_currencies
    AccountListExhibit.new(current_account_list, nil).currency_select.collect { |k, v| [k, v] }
  end

  def actions
    Task::TASK_ACTIVITIES
  end

  def next_actions
    Task.all_next_action_options
  end

  def results
    Task.all_result_options
  end

  def bulk_update_options
    Contact.bulk_update_options(current_account_list)
  end

  def assignable_locations
    Address.new.assignable_locations.collect { |l| [l, l] }
  end
end
