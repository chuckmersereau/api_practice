require 'spec_helper'

describe Api::V2Controller do
  describe '#DATE_REGEX' do
    it 'matches date string' do
      expect('2017-12-13').to match Filtering::DATE_REGEX
    end

    it 'does not match blank' do
      expect('').to_not match Filtering::DATE_REGEX
      expect(nil).to_not match Filtering::DATE_REGEX
    end

    it 'does not match not-date string' do
      expect('last week').to_not match Filtering::DATE_REGEX
      expect('2001').to_not match Filtering::DATE_REGEX
    end
  end

  describe '#DATE_TIME_REGEX' do
    it 'matches 00:00 timezone datetime string' do
      expect('2001-02-03T04:05:06+00:00').to match Filtering::DATE_TIME_REGEX
    end

    it 'matches Z timezone datetime string' do
      expect('2001-02-03T04:05:06Z').to match Filtering::DATE_TIME_REGEX
    end

    it 'does not match blank' do
      expect('').to_not match Filtering::DATE_TIME_REGEX
      expect(nil).to_not match Filtering::DATE_TIME_REGEX
    end

    it 'does not match not-datetime string' do
      expect('last week').to_not match Filtering::DATE_TIME_REGEX
      expect('2017-12-13').to_not match Filtering::DATE_TIME_REGEX
    end
  end

  describe '#DATE_RANGE_REGEX' do
    it 'matches date range string' do
      expect('2017-12-13..2018-01-13').to match Filtering::DATE_RANGE_REGEX
      expect('2017-12-13...2018-01-13').to match Filtering::DATE_RANGE_REGEX
    end

    it 'does not match blank' do
      expect('').to_not match Filtering::DATE_RANGE_REGEX
      expect(nil).to_not match Filtering::DATE_RANGE_REGEX
    end

    it 'does not match not-date range string' do
      expect('last week').to_not match Filtering::DATE_RANGE_REGEX
      expect('2017-12-13').to_not match Filtering::DATE_RANGE_REGEX
    end
  end

  describe '#DATE_TIME_RANGE_REGEX' do
    it 'matches datetime range string' do
      expect('2001-02-03T04:05:06+00:00..2001-02-03T04:05:06+00:00').to match Filtering::DATE_TIME_RANGE_REGEX
      expect('2001-02-03T04:05:06Z...2001-02-03T04:05:06Z').to match Filtering::DATE_TIME_RANGE_REGEX
    end

    it 'does not match blank' do
      expect('').to_not match Filtering::DATE_TIME_RANGE_REGEX
      expect(nil).to_not match Filtering::DATE_TIME_RANGE_REGEX
    end

    it 'does not match not-datetime range string' do
      expect('last week').to_not match Filtering::DATE_TIME_RANGE_REGEX
      expect('2017-12-13..2018-01-13').to_not match Filtering::DATE_TIME_RANGE_REGEX
    end
  end
end
