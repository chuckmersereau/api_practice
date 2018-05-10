require 'rails_helper'

RSpec.describe Reports::AppointmentResultsPeriod, type: :model do
  let(:account_list) { create(:account_list) }
  let(:primary_appeal) do
    appeal = create(:appeal, account_list: account_list)
    account_list.update(primary_appeal: appeal)
    appeal
  end
  let(:second_appeal) { create(:appeal, account_list: account_list) }

  let(:end_date) { Date.new(2018, 4, 30).end_of_day }
  let(:params) { { account_list: account_list, start_date: Date.new(2018, 4, 1).beginning_of_day, end_date: end_date } }

  # use method to bust caching inside of the report
  def report
    described_class.new(params)
  end

  let!(:new_partner_contact) do
    create(:contact, account_list: account_list, status: 'Appointment Scheduled', created_at: '2018-03-04 13:00:00')
  end
  let!(:awaiting_decision_contact) do
    create(:contact, account_list: account_list, status: 'Call for Decision', created_at: '2018-03-04 13:00:00')
  end
  let!(:existing_partner_contact) do
    create(:contact, account_list: account_list, status: 'Partner - Financial',
                     pledge_amount: 10, created_at: '2018-03-04 13:00:00')
  end

  # this contact covers the use-case that the contact is created with a financial status
  let!(:new_financial_partner) do
    create(:contact, account_list: account_list, status: 'Partner - Financial',
                     pledge_amount: 10, created_at: '2018-04-07 12:00:00')
  end

  describe '#individual_appointments' do
    let!(:appointment1) do
      create(:task, activity_type: 'Appointment', start_at: '2018-04-04 12:00:00', completed_at: '2018-04-04 13:00:00',
                    account_list: account_list, completed: true, contacts: [new_partner_contact])
    end
    let!(:appointment2) do
      create(:task, activity_type: 'Appointment', start_at: '2018-04-05 12:00:00', completed_at: '2018-04-05 13:00:00',
                    account_list: account_list, completed: true, contacts: [awaiting_decision_contact])
    end
    let!(:appointment3) do
      create(:task, activity_type: 'Appointment', start_at: '2018-04-06 12:00:00', completed_at: '2018-04-06 13:00:00',
                    account_list: account_list, completed: true, contacts: [existing_partner_contact])
    end
    let!(:appointment4) do
      create(:task, activity_type: 'Appointment', start_at: '2018-04-07 13:00:00', completed_at: '2018-04-07 13:00:00',
                    account_list: account_list, completed: true, contacts: [new_financial_partner])
    end

    it 'counts appointments on account list' do
      expect(report.individual_appointments).to eq 4
    end

    it 'does not count appointments outside time window' do
      appointment1.update(start_at: '2018-05-01 00:00:00')

      expect(report.individual_appointments).to eq 3
    end

    it 'does not count attempted appointments' do
      appointment1.update(result: 'Attempted')

      expect(report.individual_appointments).to eq 3
    end
  end

  describe '#group_appointments' do
    it 'counts group_appointments on account list'
  end

  describe '#new_monthly_partners' do
    it 'counts contacts changing to financial partners' do
      travel_to '2018-04-11 18:30' do
        new_partner_contact.update(status: 'Partner - Financial')
      end
      travel_to '2018-04-11 18:31' do
        new_partner_contact.update(pledge_amount: 100)
        existing_partner_contact.update(pledge_amount: 15)
      end

      expect(report.new_monthly_partners).to eq 2
    end

    it 'does not count if the partner did not set a pledge_amount' do
      travel_to('2018-03-11') { new_partner_contact.update(pledge_amount: nil) }
      expect do
        travel_to('2018-04-11') { new_partner_contact.update(status: 'Partner - Financial') }
      end.to_not change { report.new_monthly_partners }
    end

    it 'does counts if the partner set a pledge_amount' do
      expect do
        travel_to('2018-03-11') { new_partner_contact.update(status: 'Partner - Financial', pledge_amount: nil) }
        travel_to('2018-04-11') { new_partner_contact.update(pledge_amount: 100) }
      end.to change { report.new_monthly_partners }.by(1)
    end

    it 'does not count changes before the window' do
      expect do
        travel_to('2018-03-15') { new_partner_contact.update(status: 'Partner - Financial', pledge_amount: 100) }
      end.to_not change { report.new_monthly_partners }
    end

    it 'does not count changes after the window' do
      expect do
        travel_to('2018-05-01 18:30') { new_partner_contact.update(status: 'Partner - Financial', pledge_amount: 100) }
      end.to_not change { report.new_monthly_partners }
    end

    it 'counts contacts who later changed away from Partner - Financial' do
      travel_to('2018-04-11') { new_partner_contact.update(status: 'Partner - Financial', pledge_amount: 100) }
      travel_to('2018-06-11') { new_partner_contact.update(status: 'Partner - Special') }

      expect(report.new_monthly_partners).to eq 2
    end
  end

  describe '#new_special_pledges' do
    it 'counts appointments resulting in pledges to primary appeal' do
      expect do
        travel_to '2018-04-11 18:30' do
          create(:pledge, contact: awaiting_decision_contact, appeal: primary_appeal)
        end
      end.to change { report.new_special_pledges }.by 1
    end

    it 'does not count appointments resulting in pledges to non-primary appeal' do
      expect do
        travel_to '2018-04-11 18:30' do
          create(:pledge, contact: awaiting_decision_contact, appeal: second_appeal)
        end
      end.to_not change { report.new_special_pledges }
    end

    it 'does not count pledges made before period' do
      expect do
        travel_to '2018-03-30 18:30' do
          create(:pledge, contact: awaiting_decision_contact, appeal: primary_appeal)
        end
      end.to_not change { report.new_special_pledges }
    end
  end

  describe '#monthly_increase' do
    it 'counts the change in monthly support' do
      travel_to '2018-04-11 18:30' do
        new_partner_contact.update(status: 'Partner - Financial')
      end
      travel_to '2018-04-11 18:31' do
        new_partner_contact.update(pledge_amount: 100)
        existing_partner_contact.update(pledge_amount: 15)
      end

      # 100 for new_partner_contact, 10 for new_financial_partner, and 5 for existing_partner_contact
      expect(report.monthly_increase).to eq 115
    end

    it 'does not count changes after period' do
      travel_to '2018-04-11 18:30' do
        new_partner_contact.update(status: 'Call for Decision')
      end
      travel_to(end_date + 1.day) do
        new_partner_contact.update(status: 'Partner - Financial', pledge_amount: 100)
        existing_partner_contact.update(pledge_amount: 15)
      end

      # 10 for new_financial_partner
      expect(report.monthly_increase).to eq 10
    end

    it 'converts the changed amount into account currency' do
      allow(CurrencyRate).to receive(:latest_for).with('DBL').and_return(0.5)
      allow(CurrencyRate).to receive(:latest_for).with('USD').and_return(1)

      travel_to '2018-04-11 18:31' do
        new_partner_contact.update(status: 'Partner - Financial', pledge_amount: 100, pledge_currency: 'DBL')
        existing_partner_contact.update(pledge_amount: 15)
      end

      # 200 for new_partner_contact, 10 for new_financial_partner, and 5 for existing_partner_contact
      expect(report.monthly_increase).to eq 215
    end

    it 'knows if it should count only positive or negative too'
  end

  describe '#pledge_increase' do
    it 'counts the new pledges to primary appeal' do
      travel_to end_date.to_datetime.end_of_day do
        create(:pledge, contact: awaiting_decision_contact, appeal: primary_appeal, amount: 50)
      end

      expect(report.pledge_increase).to eq 50
    end

    it 'does not count appointments resulting in pledges to non-primary appeal' do
      travel_to '2018-04-11 18:30' do
        create(:pledge, contact: awaiting_decision_contact, appeal: second_appeal)
      end

      expect(report.pledge_increase).to eq 0
    end

    it 'does not count pledges made before and after period' do
      travel_to '2018-03-30 18:30' do
        create(:pledge, contact: awaiting_decision_contact, appeal: primary_appeal)
      end
      travel_to '2018-05-11 18:30' do
        create(:pledge, contact: new_partner_contact, appeal: primary_appeal)
      end

      expect(report.pledge_increase).to eq 0
    end
  end
end
