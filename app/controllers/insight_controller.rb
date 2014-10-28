require 'rexml/document'

class InsightController < ApplicationController
  before_action :find_contact
  before_action :find_donor_accounts

  def index
    @page_title = _('Insight')
    @current_user = current_user

    insight = Obiee.new
    session_id = insight.auth_client

    sql = insight.report_sql(session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                             'mpdxRecurrDesig',
                            Person::RelayAccount.where(person_id: current_user.id ).pluck('designation')[0])

    xsd_results =  insight.report_results(session_id,sql)
    dom = Hash.from_trusted_xml(xsd_results).deep_symbolize_keys

    @xsd_results = dom[:rowset][:Row]
    @acct = current_account_list

  end

  def find_contact
    @contact = current_account_list.contacts.where(id: params[:contact_id]).first if params[:contact_id]
  end

  def find_donor_accounts
    @donor_accounts = []
    if @contact
      @contact.donor_accounts.each do |da|
        @donor_accounts << [ "(#{da.account_number})", da.id ]
      end
    else
      current_account_list.contacts.active.joins(:donor_accounts).includes(:donor_accounts).each do |c|
        c.donor_accounts.each do |da|
          @donor_accounts << ["(#{da.account_number})", da.id]
        end
      end
      @donor_accounts.sort_by!(&:first)
    end
  end

end