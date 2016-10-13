require 'spec_helper'

describe Appeal::AppealContactsExcluder do
  let(:account_list) { create(:account_list) }
  let(:appeal) { create(:appeal, account_list: account_list) }
  let(:designation_account_one) { create(:designation_account) }
  let(:designation_account_two) { create(:designation_account) }
  let(:donor_account_one) { create(:donor_account) }
  let(:donor_account_two) { create(:donor_account) }
  let(:contact_one) { create(:contact, account_list: account_list) }
  let(:contact_two) { create(:contact, account_list: account_list) }

  before do
    account_list.designation_accounts << designation_account_one
    account_list.designation_accounts << designation_account_two
    contact_one.donor_accounts << donor_account_one
    contact_two.donor_accounts << donor_account_two
  end

  describe '#excludes_scopes' do
    subject { Appeal::AppealContactsExcluder.new(appeal: appeal).excludes_scopes(Contact.all, excludes) }

    context 'excluding special gift in last 3 months' do
      let(:excludes) { { specialGift3months: 'true' } }

      context 'when donors giving monthly' do
        before do
          Contact.update_all(pledge_frequency: 1, pledge_amount: 100)
          [0, 1, 2, 3, 4].each do |num|
            create(:donation, donor_account: donor_account_one, designation_account: designation_account_one, amount: 100, donation_date: num.months.ago)
            create(:donation, donor_account: donor_account_two, designation_account: designation_account_two, amount: 100, donation_date: num.months.ago)
          end
        end
        it 'includes contacts that gave their normal amount in the past 3 months' do
          expect(subject).to match_array [contact_one, contact_two]
        end
        it 'excludes contacts that gave extra within the past 3 months' do
          create(:donation, donor_account: donor_account_one, designation_account: designation_account_one, amount: 100, donation_date: 1.day.ago) # Contact one gives extra
          expect(subject).to match_array [contact_two]
        end
      end

      context 'when donors giving annually' do
        before do
          Contact.update_all(pledge_frequency: 12)
          create(:donation, donor_account: donor_account_one, designation_account: designation_account_one, amount: 100, donation_date: 9.months.ago)
          create(:donation, donor_account: donor_account_two, designation_account: designation_account_two, amount: 100, donation_date: 9.months.ago)
        end
        it 'includes contacts that gave their normal amount in the past 3 months' do
          expect(subject).to match_array [contact_one, contact_two]
        end
        it 'excludes contacts that gave extra within the past 3 months' do
          create(:donation, donor_account: donor_account_one, designation_account: designation_account_one, amount: 100, donation_date: 2.months.ago) # Contact one gives extra
          expect(subject).to match_array [contact_two]
        end
      end
    end
  end
end
