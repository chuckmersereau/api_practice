# this class is responsible for building the periods and meta for the report
class Reports::AppointmentResults < Reports::Base
  def meta(fields = {})
    results_period_fields = fields['reports_appointment_results_periods']
    size = periods_data.count
    available_fields = [:individual_appointments,
                        :group_appointments,
                        :new_monthly_partners,
                        :new_special_pledges,
                        :monthly_increase,
                        :pledge_increase]
    available_fields.each_with_object({}) do |key, hash|
      next unless results_period_fields.nil? || results_period_fields.include?(key.to_s)
      hash["average_#{key}"] = (periods_data.sum(&key) / size.to_d).round
    end
  end

  protected

  def generate_report_for_period(start_date:, end_date:)
    Reports::AppointmentResultsPeriod.new(account_list: account_list,
                                          start_date: start_date,
                                          end_date: end_date)
  end
end
