class Api::V2::Contacts::Tags::BulkController < Api::V2::BulkController
  include BulkTaggable

  resource_type :tags

  def create
    load_contacts
    authorize_contacts
    add_tags_to_contacts
    render_contacts
  end

  def destroy
    load_tags
    authorize_tags
    destroy_tags
  end

  private

  def add_tags_to_contacts
    @contacts.each do |contact|
      contact.tag_list.add(*tag_names)
      contact.save!
    end
  end

  def authorize_tags
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def authorize_contacts
    @contacts.each do |contact|
      authorize(contact, :update?)
    end
  end

  def contact_uuids
    filter_params[:contact_ids].to_s.split(',').map(&:strip)
  end

  def contacts_query
    {
      account_list: account_lists
    }.tap do |query|
      query[:uuid] = contact_uuids if contact_uuids.present?
    end
  end

  def contacts_scope
    Contact.where(contacts_query).tap(&:first!)
  end
  alias tags_scope contacts_scope

  def destroy_tags
    # We are removing tags from each contact individually here to trigger the MC export
    # on contact update. Do not change this unless you have another solution in mind to trigger that callback.
    contacts_scope.joins(:taggings).where(taggings: { id: @tags }).each do |contact|
      contact.tag_list.remove(*tag_names)
      contact.save!
    end
    @tags.destroy_all
    head :no_content
  end

  def load_contacts
    @contacts ||= contacts_scope
  end

  def load_tags
    @tags ||=
      ActsAsTaggableOn::Tagging.joins(:tag)
                               .where(taggable_type: 'Contact',
                                      taggable_id: taggable_ids,
                                      tags: { name: tag_names })
  end

  def permitted_filters
    [:account_list_id, :contact_ids]
  end

  def pundit_user
    PunditContext.new(current_user)
  end

  def render_contacts
    render json: BulkResourceSerializer.new(resources: @contacts)
  end
end
