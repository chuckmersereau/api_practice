class Api::V2::Reports::SalaryCurrencyDonationsController < Api::V2Controller
  include Reportable

  def show
    load_report
    authorize_report
    render_report
  end

  private

  def load_report
    @report ||= ::Reports::SalaryCurrencyDonations.new(report_params)
  end
end
