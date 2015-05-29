require 'spec_helper'

describe RecurringRecommendationResult do
  describe 'adding a recurring recommendation status' do
    it 'is valid with all data present' do
      FactoryGirl.create(:recurring_recommendation_result).should be_valid
    end

    it 'is invalid without contact id' do
      FactoryGirl.build(:recurring_recommendation_result, contact_id: nil).should_not be_valid
    end

    it 'is invalid without account id' do
      FactoryGirl.build(:recurring_recommendation_result, account_list_id: nil).should_not be_valid
    end

    it 'is invalid without result' do
      FactoryGirl.build(:recurring_recommendation_result, result: nil).should_not be_valid
    end
  end
end
