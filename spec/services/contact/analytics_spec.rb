require 'rails_helper'

RSpec.describe Contact::Analytics, type: :model do
  let(:today)        { Date.current }
  let(:account_list) { create(:account_list) }

  describe '#initialize' do
    it 'initializes with a contacts collection' do
      contacts = double(:contacts)

      analytics = Contact::Analytics.new(contacts)
      expect(analytics.contacts).to eq contacts
    end
  end

  describe '#first_gift_not_received_count' do
    before do
      create(:contact, account_list_id: account_list.id, status: 'Partner - Financial', pledge_received: false)
      create(:contact, account_list_id: account_list.id, status: 'Partner - Financial', pledge_received: true)
      create(:contact, account_list_id: account_list.id, status: nil, pledge_received: true)
    end

    let(:contacts) { Contact.where(account_list_id: account_list.id) }

    it "gives the count of financial partners where pledge hasn't been received" do
      analytics = Contact::Analytics.new(contacts)
      expect(analytics.first_gift_not_received_count).to eq(1)
    end
  end

  describe '#partners_30_days_late_count' do
    before do
      create(:contact, account_list: account_list, status: 'Partner - Financial')
        .update_columns(late_at: 10.days.ago)

      create(:contact, account_list: account_list, status: 'Partner - Financial')
        .update_columns(late_at: 30.days.ago)

      create(:contact, account_list: account_list, status: 'Partner - Financial')
        .update_columns(late_at: 31.days.ago)

      create(:contact, account_list: account_list, status: 'Partner - Financial')
        .update_columns(late_at: 61.days.ago)

      create(:contact, account_list: account_list, status: nil, pledge_received: true)
    end

    let(:contacts) { Contact.where(account_list_id: account_list.id) }

    it 'gives the count of financial partners who are late between 31 and 60 days' do
      analytics = Contact::Analytics.new(contacts)
      expect(analytics.partners_30_days_late_count).to eq(1)
    end
  end

  describe '#partners_60_days_late_count' do
    before do
      create(:contact, account_list: account_list, status: 'Partner - Financial')
        .update_columns(late_at: 10.days.ago)

      create(:contact, account_list: account_list, status: 'Partner - Financial')
        .update_columns(late_at: 30.days.ago)

      create(:contact, account_list: account_list, status: 'Partner - Financial')
        .update_columns(late_at: 61.days.ago)

      create(:contact, account_list: account_list, status: 'Partner - Financial')
        .update_columns(late_at: 90.days.ago)

      create(:contact, account_list: account_list, status: nil, pledge_received: true)
    end

    let(:contacts) { Contact.where(account_list_id: account_list.id) }

    it 'gives the count of financial partners who are late greater than 61 days' do
      analytics = Contact::Analytics.new(contacts)
      expect(analytics.partners_60_days_late_count).to eq(2)
    end
  end

  describe '#birthdays_this_week' do
    let(:person_with_birthday_this_week) do
      create(:person, birthday_month: today.month,
                      birthday_day: today.day,
                      birthday_year: (today + 10.years).year)
    end

    let(:person_with_birthday_next_week) do
      date = today + 1.week

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date + 10.years).year)
    end

    let(:person_with_birthday_last_week) do
      date = today - 1.week

      create(:person, birthday_month: date.month,
                      birthday_day: date.day,
                      birthday_year: (date - 10.years).year)
    end

    let(:deceased_person_with_birthday_this_week) do
      create(:person, birthday_month: today.month,
                      birthday_day: today.day,
                      birthday_year: (today + 10.years).year,
                      deceased: true)
    end

    let(:person_with_birthday_this_week_belonging_to_inactive_contact) do
      create(:person, birthday_month: today.month,
                      birthday_day: today.day,
                      birthday_year: (today + 10.years).year)
    end

    let(:active_contact)   { create(:contact, status: 'Partner - Financial') }
    let(:inactive_contact) { create(:contact, status: 'Not Interested') }

    let(:contacts) { Contact.where(id: [active_contact.id, inactive_contact.id]) }

    before do
      active_contact.people << person_with_birthday_this_week
      active_contact.people << person_with_birthday_next_week
      active_contact.people << person_with_birthday_last_week
      active_contact.people << deceased_person_with_birthday_this_week

      inactive_contact.people << person_with_birthday_this_week_belonging_to_inactive_contact
    end

    it "pulls the people and associated contacts who's birthdays are this week" do
      analytics = Contact::Analytics.new(contacts)
      found_person_ids = analytics.birthdays_this_week.map(&:person).map(&:id)
      found_contact_ids = analytics.birthdays_this_week.map(&:parent_contact).map(&:id)

      expect(found_person_ids.count).to eq(1)
      expect(found_person_ids).to     include person_with_birthday_this_week.id
      expect(found_person_ids).not_to include person_with_birthday_last_week.id
      expect(found_person_ids).not_to include person_with_birthday_next_week.id
      expect(found_person_ids).not_to include deceased_person_with_birthday_this_week.id
      expect(found_person_ids).not_to include person_with_birthday_this_week_belonging_to_inactive_contact.id
      expect(found_contact_ids).to    include person_with_birthday_this_week.contacts.ids.first
    end
  end

  describe '#anniversaries_this_week' do
    let(:person_with_anniversary_this_week) do
      create(:person, anniversary_month: today.month,
                      anniversary_day: today.day,
                      anniversary_year: (today + 10.years).year)
    end

    let(:deceased_person_with_anniversary_this_week) do
      create(:person, anniversary_month: today.month,
                      anniversary_day: today.day,
                      anniversary_year: (today + 10.years).year,
                      deceased: true)
    end

    let(:person_with_anniversary_next_week) do
      date = today + 1.week

      create(:person, anniversary_month: date.month,
                      anniversary_day: date.day,
                      anniversary_year: (date + 10.years).year)
    end

    let(:person_with_anniversary_last_week) do
      date = today - 1.week

      create(:person, anniversary_month: date.month,
                      anniversary_day: date.day,
                      anniversary_year: (date - 10.years).year)
    end

    let(:active_contact_with_person_with_anniversary_this_week) do
      create(:contact, account_list_id: account_list.id, status: 'Partner - Financial')
    end

    let(:active_contact_with_deceased_person_with_anniversary_this_week) do
      create(:contact, account_list_id: account_list.id, status: 'Partner - Financial')
    end

    let(:active_contact_with_person_with_anniversary_last_week) do
      create(:contact, account_list_id: account_list.id, status: 'Partner - Financial')
    end

    let(:active_contact_with_person_with_anniversary_next_week) do
      create(:contact, account_list_id: account_list.id, status: 'Partner - Financial')
    end

    let(:inactive_contact_with_person_with_anniversary_this_week) do
      create(:contact, account_list_id: account_list.id, status: 'Not Interested')
    end

    let(:contacts) do
      ids = [
        active_contact_with_person_with_anniversary_this_week,
        active_contact_with_deceased_person_with_anniversary_this_week,
        active_contact_with_person_with_anniversary_next_week,
        active_contact_with_person_with_anniversary_last_week,
        inactive_contact_with_person_with_anniversary_this_week
      ].map(&:id)

      Contact.where(id: ids)
    end

    before do
      active_contact_with_person_with_anniversary_this_week.people          << person_with_anniversary_this_week
      active_contact_with_deceased_person_with_anniversary_this_week.people << deceased_person_with_anniversary_this_week
      active_contact_with_person_with_anniversary_next_week.people          << person_with_anniversary_next_week
      active_contact_with_person_with_anniversary_last_week.people          << person_with_anniversary_last_week

      inactive_contact_with_person_with_anniversary_this_week.people << person_with_anniversary_this_week
    end

    it 'pulls the contacts with people having anniversaries this week' do
      analytics = Contact::Analytics.new(contacts)
      found_ids = analytics.anniversaries_this_week.ids

      expect(found_ids.count).to eq(1)

      expect(found_ids).to     include active_contact_with_person_with_anniversary_this_week.id
      expect(found_ids).not_to include active_contact_with_deceased_person_with_anniversary_this_week.id
      expect(found_ids).not_to include active_contact_with_person_with_anniversary_last_week.id
      expect(found_ids).not_to include active_contact_with_person_with_anniversary_next_week.id
      expect(found_ids).not_to include inactive_contact_with_person_with_anniversary_this_week.id
    end
  end
end
