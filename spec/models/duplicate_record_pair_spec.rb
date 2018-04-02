require 'rails_helper'

describe DuplicateRecordPair, type: :model do
  let!(:account_list) { create(:account_list) }
  let!(:record_one) { create(:contact).tap { |c| account_list.contacts << c } }
  let!(:record_two) { create(:contact).tap { |c| account_list.contacts << c } }
  let!(:record_three) { create(:contact).tap { |c| account_list.contacts << c } }

  it 'sorts the record ids' do
    drp = DuplicateRecordPair.create!(account_list: account_list, record_one: record_one,
                                      record_two: record_two, reason: 'Testing')
    expect(drp.record_one_id).to eq(record_one.id)
    expect(drp.record_two_id).to eq(record_two.id)
    expect(drp.record_two.created_at > drp.record_one.created_at).to eq(true)

    drp.update!(record_one_id: record_two.id, record_two_id: record_one.id)
    expect(drp.record_one_id).to eq(record_one.id)
    expect(drp.record_two_id).to eq(record_two.id)

    DuplicateRecordPair.delete_all

    drp = DuplicateRecordPair.create!(account_list: account_list, record_one: record_two,
                                      record_two: record_one, reason: 'Testing')
    expect(drp.record_one_id).to eq(record_one.id)
    expect(drp.record_two_id).to eq(record_two.id)
  end

  it 'validates presence of both ids' do
    drp = DuplicateRecordPair.new(account_list: account_list, record_one: record_one,
                                  record_two: nil, reason: 'Testing')
    expect(drp.valid?).to eq(false)
    drp = DuplicateRecordPair.new(account_list: account_list, record_one: nil,
                                  record_two: record_two, reason: 'Testing')
    expect(drp.valid?).to eq(false)
    drp = DuplicateRecordPair.new(account_list: account_list, record_one: nil,
                                  record_two: nil, reason: 'Testing')
    expect(drp.valid?).to eq(false)
    drp = DuplicateRecordPair.new(account_list: account_list, record_one: record_one,
                                  record_two: record_two, reason: 'Testing')
    expect(drp.valid?).to eq(true)
  end

  it 'validates that both records have the same type' do
    drp = DuplicateRecordPair.create!(account_list: account_list, record_one: record_one,
                                      record_two: record_two, reason: 'Testing')
    expect(drp.valid?).to eq(true)
    drp.record_one_type = 'Person'
    expect(drp.valid?).to eq(false)
    drp.record_one_type = 'Contact'
    expect(drp.valid?).to eq(true)
  end

  it 'validates that both records belong to the same AccountList' do
    other_account_list = create(:account_list)
    other_contact = create(:contact).tap { |c| other_account_list.contacts << c }
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing'
      )
    end.to_not raise_error
    expect do
      DuplicateRecordPair.create!(
        account_list: other_account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: other_contact,
        record_two: record_two,
        reason: 'Testing'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: other_contact,
        reason: 'Testing'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'validates that the pair is unique' do
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing 1',
        ignore: true
      )
    end.to_not raise_error

    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing 2',
        ignore: true
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_two,
        record_two: record_one,
        reason: 'Testing 3',
        ignore: true
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing 4',
        ignore: false
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_two,
        record_two: record_one,
        reason: 'Testing 5',
        ignore: false
      )
    end.to raise_error(ActiveRecord::RecordInvalid)

    expect(DuplicateRecordPair.count).to eq(1)
    DuplicateRecordPair.first.update!(ignore: false)

    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing 2',
        ignore: true
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_two,
        record_two: record_one,
        reason: 'Testing 3',
        ignore: true
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing 4',
        ignore: false
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_two,
        record_two: record_one,
        reason: 'Testing 5',
        ignore: false
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'validates that a record cannot be in multiple pairs' do
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing'
      )
    end.to_not raise_error
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_two,
        reason: 'Testing'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_two,
        record_two: record_one,
        reason: 'Testing'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_two,
        record_two: record_three,
        reason: 'Testing'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_three,
        record_two: record_two,
        reason: 'Testing'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)

    DuplicateRecordPair.first.update!(ignore: true)
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_one,
        record_two: record_three,
        reason: 'Testing'
      )
    end.to_not raise_error
    expect do
      DuplicateRecordPair.create!(
        account_list: account_list,
        record_one: record_three,
        record_two: record_two,
        reason: 'Testing'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)

    expect(DuplicateRecordPair.count).to eq(2)
  end

  describe 'scope type' do
    let!(:drp1) do
      DuplicateRecordPair.create!(account_list: account_list, record_one: record_one,
                                  record_two: record_two, reason: 'Testing')
    end
    let!(:drp2) do
      DuplicateRecordPair.create!(account_list: account_list, record_one: create(:contact, account_list: account_list),
                                  record_two: create(:contact, account_list: account_list), reason: 'Testing')
    end

    it "returns DuplicateRecordPair's with the expected type" do
      expect(DuplicateRecordPair.type('Contact').to_a).to contain_exactly(drp1, drp2)
      expect(DuplicateRecordPair.type('Person').to_a).to eq([])
    end
  end

  describe '#type' do
    let(:duplicate_record_pair) do
      DuplicateRecordPair.create!(account_list: account_list, record_one: record_one,
                                  record_two: record_two, reason: 'Testing')
    end

    it 'returns the type if they are the same' do
      expect(duplicate_record_pair.type).to eq('Contact')
      duplicate_record_pair.record_one_type = 'Asdf'
      expect(duplicate_record_pair.type).to eq(nil)
      duplicate_record_pair.record_two_type = 'Asdf'
      expect(duplicate_record_pair.type).to eq('Asdf')
    end
  end

  describe '#records' do
    let(:duplicate_record_pair) do
      DuplicateRecordPair.create!(account_list: account_list, record_one: record_one,
                                  record_two: record_two, reason: 'Testing')
    end

    it 'returns the record pair as an array' do
      expect(duplicate_record_pair.records).to eq([record_one, record_two])
    end
  end

  describe '#ids' do
    let(:duplicate_record_pair) do
      DuplicateRecordPair.create!(account_list: account_list, record_one: record_one,
                                  record_two: record_two, reason: 'Testing')
    end

    it 'returns the record ids as an array' do
      expect(duplicate_record_pair.ids).to eq([record_one.id, record_two.id])
    end
  end
end
