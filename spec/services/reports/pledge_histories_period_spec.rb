require 'rails_helper'

RSpec.describe Reports::PledgeHistoriesPeriod, type: :model do
  let(:account_list) { create(:account_list, salary_currency: 'USD') }
  let(:end_date) { Date.new(2018, 3, 30).end_of_day }
  let(:params) { { account_list: account_list, end_date: end_date } }
  let(:contact_1) { create(:contact, account_list: account_list) }
  let(:contact_2) { create(:contact, account_list: account_list) }
  let(:contact_3) { create(:contact, account_list: account_list) }

  # use method to bust caching inside of the report
  def report
    described_class.new(params)
  end

  shared_examples 'expect method to return amounts' do |options|
    context 'multiple partner_status_logs ahead' do
      let!(:partner_status_log_1) do
        contact_1.partner_status_logs.create(
          pledge_amount: 10,
          pledge_frequency: 2,
          pledge_received: options[:pledge_received],
          recorded_on: end_date + 1.week
        )
      end
      before do
        contact_1.partner_status_logs.create(
          pledge_amount: 20,
          pledge_frequency: 1,
          pledge_received: options[:pledge_received],
          recorded_on: end_date + 2.weeks
        )
        contact_2.partner_status_logs.create(
          pledge_amount: 10,
          pledge_frequency: 1,
          pledge_received: options[:pledge_received],
          recorded_on: end_date + 2.weeks
        )
        contact_2.partner_status_logs.create(
          pledge_amount: 20,
          pledge_frequency: 1,
          pledge_received: options[:pledge_received],
          recorded_on: end_date + 3.weeks
        )
        contact_3.partner_status_logs.create(
          pledge_amount: 10,
          pledge_frequency: 2,
          pledge_received: !options[:pledge_received],
          recorded_on: end_date + 3.weeks
        )
      end

      it 'should return first partner_status_log amount' do
        expect(report.send(options[:method])).to eq 15
      end

      context 'partner_status_log has different currency' do
        before do
          CurrencyRate.create(exchanged_on: end_date, code: 'CAD', rate: 0.5, source: 'test')
          partner_status_log_1.update_attribute(:pledge_currency, 'CAD')
        end

        it 'should return partner_status_log amount coverted to account_list currency' do
          expect(report.send(options[:method])).to eq 20
        end
      end
    end

    context 'no partner_status_logs ahead' do
      let!(:contact_1) do
        create(:contact,
               account_list: account_list,
               pledge_amount: 10,
               pledge_frequency: 2,
               pledge_received: options[:pledge_received])
      end
      let!(:contact_2) do
        create(:contact,
               account_list: account_list,
               pledge_amount: 10,
               pledge_frequency: 1,
               pledge_received: options[:pledge_received])
      end
      let!(:contact_3) do
        create(:contact,
               account_list: account_list,
               pledge_amount: 10,
               pledge_frequency: 2,
               pledge_received: !options[:pledge_received])
      end

      context 'contact.created_at > date' do
        before do
          contact_1.update_attribute(:created_at, end_date + 2.weeks)
          contact_2.update_attribute(:created_at, end_date + 2.weeks)
          contact_3.update_attribute(:created_at, end_date + 2.weeks)
        end

        it 'should return no amount' do
          expect(report.send(options[:method])).to eq 0
        end
      end

      context 'contact.created_at < date' do
        before do
          contact_1.update_attribute(:created_at, end_date - 2.weeks)
          contact_2.update_attribute(:created_at, end_date - 2.weeks)
          contact_3.update_attribute(:created_at, end_date - 2.weeks)
        end

        it 'should return contact amount' do
          expect(report.send(options[:method])).to eq 15
        end

        context 'contact has different currency' do
          before do
            CurrencyRate.create(exchanged_on: end_date, code: 'CAD', rate: 0.5, source: 'test')
            contact_1.update_attribute(:pledge_currency, 'CAD')
          end

          it 'should return partner_status_log amount coverted to account_list currency' do
            expect(report.send(options[:method])).to eq 20
          end
        end
      end
    end
  end

  describe '#pledged' do
    include_examples 'expect method to return amounts', method: :pledged, pledge_received: false
  end

  describe '#received' do
    include_examples 'expect method to return amounts', method: :received, pledge_received: true
  end
end
