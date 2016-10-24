class Api::V1::ContactsController < Api::V1::BaseController
  def index
    order = params[:order] || 'contacts.name'

    filtered_contacts = Contact::Filterer.new(params[:filters]).filter(contacts, current_account_list)
    inactivated = contacts.inactive.where('updated_at > ?', Time.at(params[:since].to_i)).pluck(:id)

    filtered_contacts = add_includes_and_order(filtered_contacts, order: order)

    if params[:since]
      meta = {
        deleted: Version.where(item_type: 'Contact', event: 'destroy', related_object_type: 'AccountList', related_object_id: current_account_list.id)
                        .where('created_at > ?', Time.at(params[:since].to_i)).pluck(:item_id),
        inactivated: inactivated
      }
    else
      meta = {}
    end

    meta.merge!(total: filtered_contacts.total_entries, from: correct_from(filtered_contacts),
                to: correct_to(filtered_contacts), page: page,
                total_pages: total_pages(filtered_contacts)) if filtered_contacts.respond_to?(:total_entries)

    meta[:has_contacts] = current_account_list.contacts.any?

    render json: filtered_contacts,
           serializer: ContactArraySerializer,
           scope: { include: includes, since: params[:since], user: current_user },
           meta: meta,
           callback: params[:callback],
           root: :contacts
  end

  def show
    contact = contacts.find(params[:id])

    meta = { previous_contact: 0, following_contact: 0 }
    current_index = contacts.index(contact)
    if current_index > 0
      meta[:previous_contact] = contacts[current_index - 1].id
    end
    if current_index < contacts.length - 1
      meta[:following_contact] = contacts[current_index + 1].id
    end

    render json: contact,
           methods: :mail_chimp_open_rate,
           scope: { include: includes, since: params[:since] },
           meta: meta,
           callback: params[:callback]
  rescue
    render json: { errors: ['Not Found'] }, callback: params[:callback], status: :not_found
  end

  def update
    contact = contacts.find(params[:id])
    if contact.update_attributes(contact_params)
      render json: contact, callback: params[:callback]
    else
      render json: { errors: contact.errors.full_messages }, callback: params[:callback], status: :bad_request
    end
  end

  def create
    contact = contacts.new(contact_params)
    if contact.save
      render json: contact, callback: params[:callback], status: :created
    else
      render json: { errors: contact.errors.full_messages }, callback: params[:callback], status: :bad_request
    end
  end

  def destroy
    contact = contacts.find(params[:id])
    contact.destroy
    render json: contact, callback: params[:callback]
  rescue
    render json: { errors: ['Not Found'] }, callback: params[:callback], status: :not_found
  end

  def bulk_destroy
    contacts = current_account_list.contacts.find(params[:ids].split(','))
    contacts.map(&:hide)
    render nothing: true
  end

  def count
    filtered_contacts = if params[:filters].present?
                          Contact::Filterer.new(params[:filters]).filter(contacts, current_account_list)
                        else
                          contacts.active
                        end

    render json: { total: filtered_contacts.count }, callback: params[:callback]
  end

  def tags
    render json: { tags: current_account_list.contact_tags }, callback: params[:callback]
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

    if attributes_to_update.present?
      contacts.update_all(attributes_to_update)
      current_account_list.mail_chimp_account.try(:queue_sync_contacts, contacts.pluck(:id))
      render nothing: true
    else
      render nothing: true, status: 400
    end
  end

  def merge
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
    render nothing: true
  end

  def save_referrals
    contact = contacts.find(params[:id] || params[:contact_id])
    multi_add = ContactMultiAdd.new(current_account_list, contact)
    contacts_attrs = params[:contacts_attributes]
    contacts, bad_contacts_count = multi_add.add_contacts(contacts_attrs)

    render json: { success: contacts, failed: bad_contacts_count }, status: 200
  end

  def basic_list
    render json: contacts.order('name').collect { |c| [c.name, c.id] }.to_json
  end

  protected

  def contacts
    current_account_list.contacts
  end

  def available_includes
    if !params[:include]
      [{ people: [:email_addresses, :phone_numbers, :facebook_account, :twitter_accounts, :linkedin_accounts, :websites] },
       { primary_person: :facebook_account }, { addresses: [:master_address] },
       :donor_accounts, :tags]
    else
      includes = []
      includes << { people: [:email_addresses, :phone_numbers, :facebook_account] } if params[:include].include?('Person.')
      includes << { addresses: [:master_address] } if params[:include].include?('Address.')
      includes << { primary_person: :facebook_account } if params[:include].include?('avatar')
      includes << :tags if params[:include].include?('Contact.tag_list')
      includes << :donor_accounts if params[:include].include?('Contact.donor_accounts')
      includes
    end
  end

  def contact_params
    @contact_params ||= params.require(:contact).permit(Contact::PERMITTED_ATTRIBUTES)
  end
end