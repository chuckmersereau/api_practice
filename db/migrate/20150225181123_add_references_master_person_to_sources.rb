class AddReferencesMasterPersonToSources < ActiveRecord::Migration
  def change
    MasterPersonSource
      .joins('LEFT JOIN master_people ON master_people.id = master_person_sources.master_person_id')
      .where('master_people.id is null')
      .each { |orphaned_m_p_s| orphaned_m_p_s.destroy }

    add_foreign_key :master_person_sources, :master_people
  end
end
