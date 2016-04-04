class TntImport::TntCodes
  # This is an ordered array of the Tnt phone types. The order matters because the tnt  PreferredPhoneType
  # is an index that into this list and the PhoneIsValidMask is a bit vector that refers to these in order too.
  TNT_PHONES = [
    { field: 'HomePhone', location: 'home', person: :both }, # index 0
    { field: 'HomePhone2', location: 'home', person: :both },
    { field: 'HomeFax', location: 'fax', person: :both },
    { field: 'OtherPhone', location: 'other', person: :both },
    { field: 'OtherFax', location: 'fax', person: :both },

    { field: 'MobilePhone', location: 'mobile', person: :primary },
    { field: 'MobilePhone2', location: 'mobile', person: :primary },
    { field: 'PagerNumber', location: 'other', person: :primary },
    { field: 'BusinessPhone', location: 'work', person: :primary },
    { field: 'BusinessPhone2', location: 'work', person: :primary },
    { field: 'BusinessFax', location: 'fax', person: :primary },
    { field: 'CompanyMainPhone', location: 'work', person: :primary },

    { field: 'SpouseMobilePhone', location: 'mobile', person: :spouse },
    { field: 'SpouseMobilePhone2', location: 'mobile', person: :spouse },
    { field: 'SpousePagerNumber', location: 'other', person: :spouse },
    { field: 'SpouseBusinessPhone', location: 'work', person: :spouse },
    { field: 'SpouseBusinessPhone2', location: 'work', person: :spouse },
    { field: 'SpouseBusinessFax', location: 'fax', person: :spouse },
    { field: 'SpouseCompanyMainPhone', location: 'work', person: :spouse } # index 18
  ]

  class << self
    def task_type(task_type_id)
      case task_type_id.to_i
      when 1 then 'Appointment'
      when 2 then 'Thank'
      when 3 then 'To Do'
      when 20 then 'Call'
      when 30 then 'Reminder Letter'
      when 40 then 'Support Letter'
      when 50 then 'Letter'
      when 60 then 'Newsletter'
      when 70 then 'Pre Call Letter'
      when 100 then 'Email'
      end
    end

    def history_result(history_result_id)
      case history_result_id.to_i
      when 1 then 'Done'
      when 2 then 'Received'
      when 3 then 'Attempted'
      end
    end

    def mpd_phase(phase)
      case phase.to_i
      when 10 then 'Never Contacted'
      when 20 then 'Ask in Future'
      when 30 then 'Contact for Appointment'
      when 40 then 'Appointment Scheduled'
      when 50 then 'Call for Decision'
      when 60 then 'Partner - Financial'
      when 70 then 'Partner - Special'
      when 80 then 'Partner - Pray'
      when 90 then 'Not Interested'
      when 95 then 'Unresponsive'
      when 100 then 'Never Ask'
      when 110 then 'Research Abandoned'
      when 130 then 'Expired Referral'
      end
    end
  end
end