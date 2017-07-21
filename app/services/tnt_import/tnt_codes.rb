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
  ].freeze

  TNT_TASK_CODES_MAPPED_TO_MPDX_TASK_TYPES = {
    1   => 'Appointment',
    2   => 'Thank',
    3   => 'To Do',
    20  => 'Call',
    30  => 'Reminder Letter',
    40  => 'Support Letter',
    50  => 'Letter',
    60  => 'Newsletter - Physical',
    65  => 'Newsletter - Email',
    70  => 'Pre Call Letter',
    100 => 'Email',
    140 => 'Facebook Message',
    150 => 'Text Message'
  }.freeze

  TNT_TASK_RESULT_CODES_MAPPED_TO_MPDX_TASK_RESULTS = {
    1 => 'Done',
    2 => 'Received',
    3 => 'Attempted'
  }.freeze

  TNT_MPD_PHASE_CODES_MAPPED_TO_MPDX_CONTACT_STATUSES = {
    0   => nil, # A "0" value for MPDPhaseID means "n/a" in Tnt
    10  => 'Never Contacted',
    20  => 'Ask in Future',
    30  => 'Contact for Appointment',
    40  => 'Appointment Scheduled',
    50  => 'Call for Decision',
    60  => 'Partner - Financial',
    70  => 'Partner - Special',
    80  => 'Partner - Pray',
    90  => 'Not Interested',
    95  => 'Unresponsive',
    100 => 'Never Ask',
    110 => 'Research Abandoned',
    130 => 'Expired Referral'
  }.freeze

  class << self
    def task_type(task_type_id)
      TNT_TASK_CODES_MAPPED_TO_MPDX_TASK_TYPES[task_type_id.to_i]
    end

    def task_status_completed?(task_status_id)
      task_status_id.to_i == 2 ? true : false
    end

    def history_result(history_result_id)
      TNT_TASK_RESULT_CODES_MAPPED_TO_MPDX_TASK_RESULTS[history_result_id.to_i]
    end

    def mpd_phase(phase)
      TNT_MPD_PHASE_CODES_MAPPED_TO_MPDX_CONTACT_STATUSES[phase.to_i]
    end
  end
end
