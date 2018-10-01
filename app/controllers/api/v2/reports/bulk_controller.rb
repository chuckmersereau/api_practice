class Api::V2::Reports::BulkController < Api::V2::BulkController
  resource_type :weeklies

  def create
    # binding.pry
    @reports = params.require(:data).map { |data| Weekly.new(id: data['weekly']['id']) }
    build_weeklies
    bulk_authorize(@reports)
    @reports.each { |weekly| weekly.save(context: persistence_context) }
    render_weeklies(@reports)
  end

  private

  def render_weeklies(weeklies)
    render json: BulkResourceSerializer.new(resources: weeklies),
           include: include_params,
           fields: field_params
  end

  def session
    Weekly.default_value
  end

  def build_weeklies
    @reports.each do |weekly|
      weekly_index = data_attribute_index(weekly)
      attributes   = params.require(:data)[weekly_index][:weekly]

      weekly.assign_attributes(
          weekly_params(attributes)
      )
      end
  end


  def data_attribute_index(weekly)
    params
        .require(:data)
        .find_index { |weekly_data| weekly_data[:weekly][:id] == weekly.id }
  end

  def weekly_params(attributes)
    attributes ||= params.require(:weekly)
    attributes.permit(:sid, :question_id, :answer)
  end

end
