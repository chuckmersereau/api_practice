class Api::V2::Reports::DonorCurrencyDonationsController < Api::V2Controller
  include Reportable

  def show
    load_report
    authorize_report
    render_report
  end

  private

  def load_report
    @report ||= ::Reports::DonorCurrencyDonations.new(report_params)
  end
end
