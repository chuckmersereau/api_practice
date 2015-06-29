require 'spec_helper'

describe RecurringRecommendationResult do
  describe 'adding a recurring recommendation status' do
    it 'is valid with all data present' do
      expect(FactoryGirl.create(:recurring_recommendation_result)).to be_valid
    end

    it 'is invalid without contact id' do
      expect(FactoryGirl.build(:recurring_recommendation_result, contact_id: nil)).not_to be_valid
    end

    it 'is invalid without account id' do
      expect(FactoryGirl.build(:recurring_recommendation_result, account_list_id: nil)).not_to be_valid
    end

    it 'is invalid without result' do
      expect(FactoryGirl.build(:recurring_recommendation_result, result: nil)).not_to be_valid
    end
  end
end
