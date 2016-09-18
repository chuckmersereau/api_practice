class ContactsController < ApplicationController
  before_action :find_contact, only: [:show, :edit, :update, :add_referrals, :save_referrals, :details, :referrals]
  before_action :setup_view_options, only: [:index, :mailing]
  before_action :setup_filters, only: [:index, :show, :mailing]
  before_action :clear_annoying_redirect_locations

  def index
    if params[:q].present?
      contacts_quick_find = ContactFilter.new(wildcard_search: params[:q], status: ['*']).filter(current_account_list.contacts, current_account_list)
      redirect_to contacts_quick_find.first if contacts_quick_find.count == 1
    end

    @page_title = _('Contacts')
    @appeals = current_account_list.appeals

    respond_to do |format|
      format.html {}

      format.csv do
        @filtered_contacts = filtered_contacts
        set_csv_xlsx_primary_emails_and_contacts
        render_csv("contacts-#{file_timestamp}")
      end

      format.xlsx do
        @filtered_contacts = filtered_contacts
        set_csv_xlsx_primary_emails_and_contacts
        render xlsx: 'index', filename: "contacts-#{file_timestamp}.xlsx"
      end
    end
  end

  def mailing
    contacts = filtered_contacts.includes(:primary_person, :spouse, :primary_address)

    @fields_mapping = {
      'Contact Name' => :name,
      'Greeting' => :greeting,
      'Envelope Greeting' => :envelope_greeting,
      'Mailing Street Address' => [:mailing_address, :csv_street],
      'Mailing City' => [:mailing_address, :city],
      'Mailing State' => [:mailing_address, :state],
      'Mailing Postal Code' => [:mailing_address, :postal_code],
      'Mailing Country' => :csv_country,
      'Address Block' => :address_block
    }
    @rows = contacts.map do |contact|
      @fields_mapping.values.map { |method| value_for_contact_field(contact, method) }
    end

    respond_to do |format|
      format.csv { render_csv("contacts-mailing-#{Time.now.strftime('%Y%m%d')}") }
    end
  end

  def show
    @page_title = @contact.name

    @filtered_contacts = filtered_contacts
  end

  def details
    respond_to do |format|
      format.html { redirect_to @contact }
      format.js
    end
  end

  def referrals
  end

  def new
    session[:contact_return_to] = request.referrer if request.referrer.present?

    @page_title = _('New Contact')

    @contact = current_account_list.contacts.new
  end

  def edit
    session[:contact_return_to] = request.referrer if request.referrer.present?

    @page_title = _('Edit - %{contact}').localize % { contact: @contact.name }
  end

  def create
    Contact.transaction do
      session[:contact_return_to] = nil if session[:contact_return_to].to_s.include?('edit')

      respond_to do |format|
        begin
          @contact = current_account_list.contacts.new(contact_params)
          if @contact.save
            format.html { redirect_to(@contact) }
          else
            format.html { render action: 'new' }
          end
        rescue Errors::FacebookLink, LinkedIn::Errors::UnauthorizedError => e
          @contact ||= current_account_list.contacts.new(contact_params.except(:people_attributes))
          flash.now[:alert] = e.message
          format.html { render action: 'new' }
        end
      end
    end
  end

  def update
    respond_to do |format|
      begin
        if @contact.update_attributes(contact_params)
          format.html { redirect_to(session[:contact_return_to] || @contact) }
          format.js
        else
          format.html { render action: 'edit' }
          format.js { render nothing: true }
        end
      rescue Errors::FacebookLink, LinkedIn::Errors::UnauthorizedError => e
        flash.now[:alert] = e.message
        format.html { render action: 'edit' }
        format.js { render nothing: true }
      end
      format.json { respond_with_bip(@contact) }
    end
  end

  def bulk_update
    contacts = current_account_list.contacts.where(id: params[:bulk_edit_contact_ids].split(','))

    next_ask_year = contact_params.delete('next_ask(1i)')
    next_ask_month = contact_params.delete('next_ask(2i)')
    next_ask_day = contact_params.delete('next_ask(3i)')
    if [next_ask_year, next_ask_month, next_ask_day].all?(&:present?)
      contact_params['next_ask'] = Date.new(next_ask_year.to_i, next_ask_month.to_i, next_ask_day.to_i)
    end

    attributes_to_update = contact_params.select { |_, v| v.present? }
    attributes_to_update['send_newsletter'] = '' if attributes_to_update['send_newsletter'] == 'none'
    return unless attributes_to_update.present?
    contacts.update_all(attributes_to_update)

    # Since update_all doesn't trigger callbacks, we need to manually sync with mail chimp
    current_account_list.mail_chimp_account.try(:queue_sync_contacts, contacts.pluck(:id))
  end

  def merge
    @page_title = _('Merge Contacts')

    params[:merge_sets] = [params[:merge_contact_ids]] if params[:merge_contact_ids]

    merged_contacts_count = 0

    params[:merge_sets].each do |ids|
      contacts = current_account_list.contacts.includes(:people).where(id: ids.split(','))
      next if contacts.length <= 1

      merged_contacts_count += contacts.length

      winner_id = if params[:dup_contact_winner].present?
                    params[:dup_contact_winner][ids]
                  else
                    contacts.max_by { |c| c.people.length }
                  end

      winner = contacts.find(winner_id)
      Contact.transaction do
        (contacts - [winner]).each do |loser|
          winner.merge(loser)
        end
      end
    end if params[:merge_sets].present?
    redirect_to :back, notice: _('You just merged %{count} contacts').localize % { count: merged_contacts_count }
  end

  def destroy
    @contact = current_account_list.contacts.find(params[:id])
    @contact.hide

    respond_to do |format|
      format.html { redirect_to contacts_path }
      format.js { render nothing: true }
    end
  end

  def bulk_destroy
    @contacts = current_account_list.contacts.find(params[:ids].split(','))
    @contacts.map(&:hide)

    respond_to do |format|
      format.html { redirect_to contacts_path }
      format.js { render nothing: true }
    end
  end

  def social_search
    if %(facebook twitter linkedin).include?(params[:network])
      @results = "Person::#{params[:network].titleize}Account".constantize.search(current_user, params)
      render layout: false
    else
      render nothing: true
    end
  end

  def add_referrals
    @modal_title = _('Add Referrals')
    @save_path = save_referrals_contact_path(@contact)
    render :add_multi
  end

  def save_referrals
    multi_add = ContactMultiAdd.new(current_account_list, @contact)
    contacts_attrs = params[:account_list][:contacts_attributes]
    @contacts, @bad_contacts_count = multi_add.add_contacts(contacts_attrs)

    unless @contacts.empty?
      flash[:notice] = _('You have successfully added %{contacts_count:referrals}.').to_str.localize %
                       { contacts_count: @contacts.length, referrals: { one: _('1 referral'), other: _('%{contacts_count} referrals') } }
    end

    if @bad_contacts_count > 0
      flash[:alert] = _("%{contacts_count:referrals} couldn't be added because they were missing a first name or you put in a bad email address.").to_str.localize %
                      { contacts_count: @bad_contacts_count,
                        referrals: { one: _('1 referral'), other: _('%{contacts_count} referrals') } }
    end

    # Can't use redirect_to because this is called with remote: true
    @redirect_path = contacts_path(filters: { referrer: [@contact.id] })
    render :redirect_script
  end

  def add_multi
    @modal_title = _('Add Contacts')
    @save_path = save_multi_contacts_path
  end

  def save_multi
    multi_add = ContactMultiAdd.new(current_account_list, @contact)
    contacts_attrs = params[:account_list][:contacts_attributes]
    @contacts, @bad_contacts_count = multi_add.add_contacts(contacts_attrs)

    unless @contacts.empty?
      flash[:notice] = _('You have successfully added %{contacts_count:contacts}.').to_str.localize %
                       { contacts_count: @contacts.length,
                         contacts: { one: _('1 contact'), other: _('%{contacts_count} contacts') } }
    end

    if @bad_contacts_count > 0
      flash[:alert] = _("%{contacts_count:contacts} couldn't be added because they were missing a first name or you put in a bad email address.").to_str.localize %
                      { contacts_count: @bad_contacts_count,
                        contacts: { one: _('1 contact'), other: _('%{contacts_count} contacts') } }
    end

    # Can't use redirect_to because this is called with remote: true
    @redirect_path = contacts_path(filters: { ids: @contacts.map(&:id).join(',') })
    render :redirect_script
  end

  def find_duplicates
    @page_title = _('Find Duplicates')

    respond_to do |format|
      format.html {}
      format.js do
        dups_finder = ContactDuplicatesFinder.new(current_account_list, current_user)
        @contact_sets, @people_sets = dups_finder.dup_contacts_then_people
      end
    end
  end

  def not_duplicates
    contacts = current_account_list.contacts.where(id: params[:ids])
    contacts.each do |contact|
      not_duplicated_with = (contact.not_duplicated_with.to_s.split(',') + params[:ids].split(',') - [contact.id.to_s]).uniq.join(',')
      contact.update_attributes(not_duplicated_with: not_duplicated_with)
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render nothing: true }
    end
  end

  private

  def set_csv_xlsx_primary_emails_and_contacts
    @csv_primary_emails_only = csv_primary_emails_only_param
    @contacts = @filtered_contacts.includes(:primary_person, :spouse, :primary_address,
                                            :tags, people: [:email_addresses, :phone_numbers])
  end

  def file_timestamp
    Time.now.strftime('%Y%m%d')
  end

  def find_contact
    @contact = current_account_list.contacts.includes(people: [:primary_email_address, :primary_phone_number, :email_addresses, :phone_numbers, :family_relationships]).find(params[:id])
  end

  def setup_filters
    current_user.contacts_filter ||= {}
    clear_filters = params.delete(:clear_filter)
    if filters_params.present? && current_user.contacts_filter[current_account_list.id.to_s] != filters_params
      @view_options[:page] = 1
      current_user.contacts_filter[current_account_list.id.to_s] = filters_params
      current_user.save
    elsif clear_filters == 'true'
      current_user.contacts_filter[current_account_list.id.to_s] = nil
      current_user.save
    end

    return if current_user.contacts_filter.blank? || current_user.contacts_filter[current_account_list.id.to_s].blank?

    @filters_params = current_user.contacts_filter[current_account_list.id.to_s]
  end

  def filtered_contacts
    filtered_contacts = current_account_list.contacts.order('contacts.name')
    filtered_contacts = if filters_params.present?
                          ContactFilter.new(filters_params).filter(filtered_contacts, current_account_list)
                        else
                          filtered_contacts.active
                        end
    filtered_contacts
  end

  def setup_view_options
    current_user.contacts_view_options ||= {}
    if params[:per_page].present? || params[:page].present?
      view_options = current_user.contacts_view_options[current_account_list.id.to_s] || {}
      if params[:per_page] && view_options[:per_page].to_s != params[:per_page]
        view_options[:page] = 1
      elsif params[:page]
        view_options[:page] = params[:page]
      end
      view_options[:per_page] = params[:per_page]

      current_user.contacts_view_options[current_account_list.id.to_s] = view_options
      current_user.save
    end

    if current_user.contacts_view_options.present? && current_user.contacts_view_options[current_account_list.id.to_s].present?
      view_options = current_user.contacts_view_options[current_account_list.id.to_s]
    end
    @view_options = view_options || params.slice(:per_page, :page)
  end

  def clear_annoying_redirect_locations
    return unless session[:contact_return_to].to_s.include?('edit') ||
                  session[:contact_return_to].to_s.include?('new')
    session[:contact_return_to] = nil
  end

  def contact_params
    @contact_params ||= params.require(:contact).permit(Contact::PERMITTED_ATTRIBUTES)
  end

  def csv_primary_emails_only_param
    @csv_primary_emails_only ||= params[:csv_primary_emails_only]
  end

  def value_for_contact_field(contact, method)
    @contacts_account_list ||= contact.account_list
    return contact.mailing_address.csv_country(@contacts_account_list.home_country) if method == :csv_country
    if method == :address_block
      return "#{contact.envelope_greeting}\n#{contact.mailing_address.to_snail.gsub("\r\n", "\n")}"
    end
    return contact.try(method) unless method.is_a?(Array)
    holder = contact
    method.each { |m| holder = holder.try(m) }
    holder
  end
end
