require 'rails_helper'

describe Contact::DuplicatePairsFinder do
  let!(:account_list) { create(:user_with_account).account_lists.first }

  let!(:unique_contact_one) do
    create(:contact, name: 'This contact should have no duplicates whatsoever', account_list: account_list).tap do |contact|
      contact.donor_accounts << create(:donor_account, account_number: '12134908719187349182374165192734283')
    end
  end

  let!(:unique_contact_two) do
    create(:contact, name: 'Another contact that is totally a special snow flake', account_list: account_list).tap do |contact|
      contact.donor_accounts << create(:donor_account, account_number: '08762912346125073571094871239487123')
    end
  end

  def build_finder
    Contact::DuplicatePairsFinder.new(account_list)
  end

  it 'does not find duplicates from a different account list' do
    create(:contact, name: 'Doe, John')
    create(:contact, name: 'Doe, John', account_list: account_list)

    expect do
      expect(build_finder.find_and_save).to eq([])
    end.to_not change { DuplicateRecordPair.count }.from(0)
  end

  context 'contacts with the same original name' do
    let!(:contact_one) { create(:contact, name: 'Doe, John', account_list: account_list) }
    let!(:contact_two) { create(:contact, name: 'Doe, John', account_list: account_list) }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change {
        DuplicateRecordPair.type('Contact').where(reason: 'Similar names', record_one_id: contact_one.id,
                                                  record_two_id: contact_two.id).count
      }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'contacts with the same rebuilt name' do
    let!(:contact_one) { create(:contact, name: 'Doe, John', account_list: account_list) }
    let!(:contact_two) { create(:contact, name: 'john b. doe', account_list: account_list) }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change { DuplicateRecordPair.where(reason: 'Similar names', record_one_id: contact_one.id, record_two_id: contact_two.id).count }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'contacts with the same rebuilt name that appear to be unhuman' do
    let!(:contact_one) { create(:contact, name: "big\n church", account_list: account_list) }
    let!(:contact_two) { create(:contact, name: 'BIG Church ', account_list: account_list) }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change { DuplicateRecordPair.where(reason: 'Similar names', record_one_id: contact_one.id, record_two_id: contact_two.id).count }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'contacts where a single name and a couple primary name match' do
    let!(:contact_one) { create(:contact, name: 'Doe, John and Jane', account_list: account_list) }
    let!(:contact_two) { create(:contact, name: 'Doe, John', account_list: account_list) }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change { DuplicateRecordPair.where(reason: 'Similar names', record_one_id: contact_one.id, record_two_id: contact_two.id).count }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'contacts couple primary name match but spouse does not' do
    let!(:contact_one) { create(:contact, name: 'Doe, John and Jane', account_list: account_list) }
    let!(:contact_two) { create(:contact, name: 'Doe, John and Sarah', account_list: account_list) }

    it 'does not find any pairs' do
      expect do
        expect(build_finder.find_and_save).to eq([])
      end.to_not change { DuplicateRecordPair.count }.from(0)
    end
  end

  context 'contacts where a single name and a couple spouse name match' do
    let!(:contact_one) { create(:contact, name: 'Doe, John and Jane', account_list: account_list) }
    let!(:contact_two) { create(:contact, name: 'Doe, Jane', account_list: account_list) }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change { DuplicateRecordPair.where(reason: 'Similar names', record_one_id: contact_one.id, record_two_id: contact_two.id).count }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'contacts couple spouse name match but primary does not' do
    let!(:contact_one) { create(:contact, name: 'Doe, John and Jane', account_list: account_list) }
    let!(:contact_two) { create(:contact, name: 'Doe, Joe and Jane', account_list: account_list) }

    it 'does not find any pairs' do
      expect do
        expect(build_finder.find_and_save).to eq([])
      end.to_not change { DuplicateRecordPair.count }.from(0)
    end
  end

  context 'contacts with the same donor account number' do
    let!(:contact_one) { create(:contact, name: 'John', account_list: account_list).tap { |contact| contact.donor_accounts << create(:donor_account, account_number: '1234') } }
    let!(:contact_two) { create(:contact, name: 'Jane', account_list: account_list).tap { |contact| contact.donor_accounts << create(:donor_account, account_number: '1234') } }

    it 'finds and saves the DuplicateRecordPair' do
      expect do
        build_finder.find_and_save
      end.to change { DuplicateRecordPair.where(reason: 'Same donor account number', record_one_id: contact_one.id, record_two_id: contact_two.id).count }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  context 'contacts names contain bad whitespace' do
    let!(:contact_one) { create(:contact, name: "\nDoe, John\r", account_list: account_list) }
    let!(:contact_two) { create(:contact, name: 'Doe,   John', account_list: account_list) }

    it 'finds and saves the DuplicateRecordPair' do
      expect { build_finder.find_and_save }.to change { DuplicateRecordPair.where(reason: 'Similar names', record_one_id: contact_one.id, record_two_id: contact_two.id).count }.from(0).to(1)
      expect(DuplicateRecordPair.count).to eq(1)
    end
  end

  it 'only returns new pairs' do
    create(:contact, name: 'Doe, Jane', account_list: account_list)
    create(:contact, name: 'Doe, Jane', account_list: account_list)

    create(:contact, name: 'Joe, John', account_list: account_list)
    create(:contact, name: 'Joe, John', account_list: account_list)

    expect do
      expect(build_finder.find_and_save.size).to eq(2)
    end.to change { DuplicateRecordPair.count }.from(0).to(2)

    expect do
      expect(build_finder.find_and_save.size).to eq(0)
    end.to_not change { DuplicateRecordPair.count }.from(2)

    DuplicateRecordPair.first.update!(ignore: true)

    expect do
      expect(build_finder.find_and_save.size).to eq(0)
    end.to_not change { DuplicateRecordPair.count }.from(2)

    create(:contact, name: 'Billy, Bob', account_list: account_list)
    create(:contact, name: 'Billy, Bob', account_list: account_list)

    expect do
      expect(build_finder.find_and_save.size).to eq(1)
    end.to change { DuplicateRecordPair.count }.from(2).to(3)
  end
end
