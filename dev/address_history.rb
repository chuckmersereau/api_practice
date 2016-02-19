def address_versions(contact)
  Version.where(related_object_type: 'Contact',
                related_object_id: contact.id,
                item_type: 'Address').order(:id)
end

def print_address_versions(contact)
  address_versions(contact).each do |v|
    o = YAML.load(v.object)
    puts "#{v.event} #{v.item_id} at #{v.created_at} street: #{o['street']} added #{o['created_at'].to_date} by #{v.whodunnit}"
  end
  nil
end

def pl_param_history(contact, detail = false)
  address_change_versions = []
  last_pl_params = nil
  contact.versions.order(:id).each do |version|
    object = YAML.load(version.object)
    pl_params = object['prayer_letters_params']
    if pl_params != last_pl_params
      data = {
        pl_params: pl_params, created_at: version.created_at
      }
      data[:version] = version if detail
      address_change_versions << data
    end
    last_pl_params = pl_params
  end
  address_change_versions << { pl_params: YAML.dump(contact.prayer_letters_params) }
  address_change_versions
end
