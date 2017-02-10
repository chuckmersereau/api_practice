class Api::GraphqlController < ApplicationController
  include JsonWebTokenAuthentication

  before_action :jwt_authorize!

  def create
    query_string = params[:query]
    query_variables = ensure_hash(params[:variables])
    result = MpdxSchema.execute(query_string, variables: query_variables, context: { current_user: current_user })
    render json: result
  end

  protected

  def current_user
    @current_user ||= User.find(jwt_payload['user_id']) if jwt_payload
  end

  private

  def ensure_hash(query_variables)
    if query_variables.blank?
      {}
    elsif query_variables.is_a?(String)
      JSON.parse(query_variables)
    else
      query_variables
    end
  end
end
