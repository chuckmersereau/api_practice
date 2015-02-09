require 'spec_helper'

describe RecurringRecommendationResults do

  describe 'adding a recurring recommendation status' do

    it 'is valid with all data present' do
      FactoryGirl.create(:recurring_recommendation_results).should be_valid
    end

    it 'is invalid without contact id' do
      FactoryGirl.build(:recurring_recommendation_results,contact_id: nil).should_not be_valid
    end

    it 'is invalid without account id' do
      FactoryGirl.build(:recurring_recommendation_results,account_list_id: nil).should_not be_valid
    end

    it 'is invalid without result' do
      FactoryGirl.build(:recurring_recommendation_results,result: nil).should_not be_valid
    end

  end
end
