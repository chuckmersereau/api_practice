require 'rails_helper'

describe ApplicationDuplicatePairsFinder do
  let!(:account_list) { create(:user_with_account).account_lists.first }

  context 'valid type' do
    before do
      expect_any_instance_of(ApplicationDuplicatePairsFinder).to receive(:record_type).and_return('Contact')
    end

    it 'initializes' do
      duplicate_pairs_finder = ApplicationDuplicatePairsFinder.new(account_list)
      expect(duplicate_pairs_finder.account_list).to eq(account_list)
      expect(duplicate_pairs_finder.duplicate_ids).to eq(Set.new)
      expect(duplicate_pairs_finder.duplicate_record_pairs).to eq([])
    end

    describe '#find_and_save' do
      it 'sends messages to find duplicates and save them' do
        duplicate_pairs_finder = ApplicationDuplicatePairsFinder.new(account_list)
        expect(duplicate_pairs_finder).to receive(:find_duplicates)
        expect(duplicate_pairs_finder).to receive(:delete_pairs_with_missing_records)
        duplicate_record_pair_double = double(:duplicate_record_pair, save: true)
        expect(duplicate_record_pair_double).to receive(:save)
        duplicate_pairs_finder.duplicate_record_pairs << duplicate_record_pair_double
        duplicate_pairs_finder.find_and_save
      end
    end
  end

  context 'invalid type' do
    it 'raises an error on initialization' do
      error = nil
      begin
        ApplicationDuplicatePairsFinder.new(account_list)
      rescue StandardError => e
        error = e
      end
      expect(error).to be_present
      expect(error.message).to eq('record_type ApplicationDuplicatePairsFinder is not valid!')
    end
  end
end
