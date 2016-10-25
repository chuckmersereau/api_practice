class Api::V1::Contacts::DonationsController < Api::V1::BaseController
  include ApplicationHelper
  before_action :load_contact

  def graph
    load_donations
    current_year = year_data(0)
    prior_year = year_data(1)
    amount = current_year[:average] - prior_year[:average]
    categories = 11.downto(0).collect { |i| l(i.months.ago.to_date, format: :month_abbrv) }
    average_series = 11.downto(0).collect { |_i| current_year[:average] }
    render json: {
      current_year: current_year,
      prior_year: prior_year,
      categories: categories,
      amount: amount,
      average_series: average_series
    }
  end

  protected

  def load_donations
    @donations ||= donation_scope.all
  end

  def donation_scope
    @contact.donations
  end

  def load_contact
    @contact ||= contact_scope.find(params[:contact_id])
  end

  def contact_scope
    current_account_list.contacts
  end

  def year_data(years_ago = 0)
    year = {}
    summary = donation_summary_from_previous_twelve_months(years_ago.years.ago)
    index = (11 + years_ago * 12).downto(years_ago * 12).map { |i| i.months.ago.to_date.beginning_of_month }
    year[:average] = (summary.values.collect { |v| v.sum(&:amount) }.reverse[0..11].sum / 12).round
    year[:series] = index.collect { |month| summary[month] || [] }.collect { |v| v.sum(&:amount).to_i }
    year
  end

  def donation_summary_from_previous_twelve_months(date_before)
    date_before = date_before.end_of_month
    date_after = (date_before - 11.months).beginning_of_month
    donation_scope.where('donation_date >= ? AND donation_date < ?', date_after, date_before).group_by do |r|
      r.donation_date.beginning_of_month
    end
  end
end
