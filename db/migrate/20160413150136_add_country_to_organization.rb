class AddCountryToOrganization < ActiveRecord::Migration
  def up
    add_column :organizations, :country, :string
    Organization.all.each do |org|
      country = guess_country(org.name)
      org.update(country: country) if country
    end
  end

  def down
    remove_column :organizations, :country
  end

  def guess_country(org_name)
    org_prefixes = ['Campus Crusade for Christ - ', 'Cru - ', 'Power To Change - ',
                    'Gospel For Asia', 'Agape']
    org_prefixes.each do |prefix|
      org_name = org_name.gsub(prefix, '')
    end
    org_name = org_name.split(' - ').last if org_name.include? ' - '
    org_name = org_name.strip
    return 'Canada' if org_name == 'CAN'
    match = ::CountrySelect::COUNTRIES_FOR_SELECT.find do |country|
      country[:name] == org_name || country[:alternatives].split(' ').include?(org_name)
    end
    return match[:name] if match
    nil
  end
end
