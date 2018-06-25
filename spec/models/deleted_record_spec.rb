require 'rails_helper'

RSpec.describe DeletedRecord, type: :model do
  let(:account_list)        { create(:account_list) }
  let(:designation_account) { create(:designation_account) }
  let(:contact)             { create(:contact, account_list: account_list) }
  let(:user)                { create(:user_with_account) }
  let!(:deleted_record) do
    create(:deleted_record,
           deleted_from_id: account_list.id,
           deleted_from_type: account_list.class.name,
           deleted_by: user,
           deleted_at: Date.current - 1.day)
  end
  let!(:second_deleted_record) do
    create(:deleted_record,
           deleted_from_id: account_list.id,
           deleted_from_type: account_list.class.name,
           deleted_by: user,
           deleted_at: Date.current - 3.days)
  end
  let!(:third_deleted_record) do
    create(:deleted_donation_record,
           deleted_from_id: designation_account.id,
           deleted_from_type: designation_account.class.name,
           deleted_by: user,
           deleted_at: Date.current - 3.days)
  end

  context 'filter' do
    it 'should filter account list ids' do
      expect(DeletedRecord.account_list_ids(account_list.id)).to include(deleted_record)
      expect(DeletedRecord.account_list_ids('1234-abce')).to_not include(deleted_record)
    end

    it 'should filter by designation account' do
      expect(DeletedRecord.where(deleted_from_id: designation_account.id)).to include(third_deleted_record)
    end

    it 'should filter since date' do
      expect(DeletedRecord.since_date(Date.current - 2.days)).to include(deleted_record)
      expect(DeletedRecord.since_date(Date.current)).to_not include(deleted_record)
    end

    it 'should filter types' do
      expect(DeletedRecord.types('Contact')).to include(deleted_record)
      expect(DeletedRecord.types('Task')).to_not include(deleted_record)
    end

    it 'should filter with multiple filters' do
      records = DeletedRecord.types('Contact').since_date(Date.today - 2.days)
      expect(records).to include(deleted_record)
      expect(records).to_not include(second_deleted_record)
      expect(records.size).to eq(1)
    end
  end
end
