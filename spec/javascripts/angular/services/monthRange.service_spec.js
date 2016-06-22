(function () {
    'use strict';

    describe('service monthRange', function () {
        var monthRange;

        beforeEach(module('mpdxApp'));
        beforeEach(inject(function (_monthRange_) {
            monthRange = _monthRange_;
            var today = moment('2014-02-08').toDate();
            jasmine.clock().mockDate(today);
        }));

        it('should be registered', function () {
            expect(monthRange).not.toEqual(null);
        });

        describe('getEndOfThisMonth function', function () {
            it('should return the last day of this month', function () {
                expect(monthRange._getEndOfThisMonth()).toEqual('2014-02-28');
            });
        });

        describe('getStartingMonth function', function () {
            it('should return the first day of the current month if only asked for a single month', function () {
                expect(monthRange.getStartingMonth(1)).toEqual('2014-02-01');
            });
            it('should return the first day of a 6 month range', function () {
                expect(monthRange.getStartingMonth(6)).toEqual('2013-09-01');
            });
            it('should return the first day of a 12 month range', function () {
                expect(monthRange.getStartingMonth(12)).toEqual('2013-03-01');
            });
        });

        describe('getPastMonths function', function () {
            it('should return an array of 2 months with the current month as the last month', function () {
                expect(monthRange.getPastMonths(2)).toEqual(['2014-01', '2014-02']);
            });
            it('should return an array of 4 months with the current month as the last month', function () {
                expect(monthRange.getPastMonths(4)).toEqual(['2013-11', '2013-12', '2014-01', '2014-02']);
            });
            it('should return an array of 12 months with the current month as the last month if the numberOfMonths param is undefined', function () {
                expect(monthRange.getPastMonths()).toEqual(['2013-03', '2013-04', '2013-05', '2013-06', '2013-07', '2013-08', '2013-09', '2013-10', '2013-11', '2013-12', '2014-01', '2014-02' ]);
            });
        });

        describe('generateMonthRange function', function () {
            it('should return an array of dates in between start and end dates', function () {
                expect(monthRange._generateMonthRange('2014-12-01', '2015-02-28')).toEqual(['2014-12','2015-01','2015-02']);
            });
        });

        describe('yearsWithMonthCounts function', function () {
            it('should return an object of years containing month counts found in range', function () {
                expect(monthRange.yearsWithMonthCounts(['2014-12','2015-01','2015-02'])).toEqual({
                    2014: 1,
                    2015: 2
                });
            });
        });

    });
})();
