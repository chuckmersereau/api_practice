(function () {
    'use strict';

    describe('service monthRange', function () {
        var monthRange;

        beforeEach(module('mpdxApp'));
        beforeEach(inject(function (_monthRange_) {
            monthRange = _monthRange_;
        }));

        it('should be registered', function () {
            expect(monthRange).not.toEqual(null);
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
