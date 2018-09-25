class Api::V2::reports::BulkController < Api::V2::BulkController

  def create
    @reports = params.require(:data).map { |data| Weekly.new(id: data['weekly']['id']) }
    build_weeklies
    bulk_authorize(@reports, :bulk_create?)
    @reports.each { |weekly| weekly.save(context: persistence_context) }
    render_weeklies(@reports)

  end

  def render_weeklies(weeklies)
    render json: BulkResourceSerializer.new(resources: weeklies),
           include: include_params,
           fields: field_params
  end

  def build_weeklies
    @reports.each do |weekly|
      weekly_index = data_attribute_index(weekly)
      attributes   = params.require(:data)[weekly_index][:weekly]

      person.assign_attributes(
          weekly_params(attributes)
      )
      end
  end

  def data_attribute_index(weekly)
    params
        .require(:data)
        .find_index { |weekly_data| weekly_data[:person][:id] == weekly.id }
  end

  def weekly_params(attributes)
    attributes ||= params.require(:weekly)
    attributes.permit(Person::PERMITTED_ATTRIBUTES)
  end

end
