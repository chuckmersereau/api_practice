(function() {
    'use strict';

    angular
        .module('mpdxApp')
        .factory('monthRange', monthRangeService);

    monthRangeService.$inject = ['moment', '_'];

    function monthRangeService(moment, _){
        var factory = {
            getPastMonths: getPastMonths,
            yearsWithMonthCounts: yearsWithMonthCounts,
            getStartingMonth: getStartingMonth,
            _getEndOfThisMonth: getEndOfThisMonth,
            _generateMonthRange: generateMonthRange
        };

        return factory;

        /** Get current date in format YYYY-MM-DD where DD is the last day of the month */
        function getEndOfThisMonth(){
            return moment().format('YYYY-MM') + '-' + moment().daysInMonth();
        }

        /** Get the month that is at the start of a X month range before and including the current month in format YYYY-MM-DD where DD is the first day of the month */
        function getStartingMonth(numberOfMonths){
            // We subtract 1 so that the current month is included
            return moment().subtract(numberOfMonths - 1, 'months').format('YYYY-MM') + '-01';
        }

        /** Get array of months from any number of months before */
        function getPastMonths(numberOfMonths){
            numberOfMonths = numberOfMonths || 12;
            return generateMonthRange(getStartingMonth(numberOfMonths), getEndOfThisMonth());
        }

        /** Get array of months between dateFrom and dateTo */
        function generateMonthRange(startDate, endDate){
            startDate = moment(startDate, "YYYY-MM-DD");
            endDate = moment(endDate, "YYYY-MM-DD");
            var range = moment.range(startDate, endDate);
            var allMonths = [];
            range.by('months', function(moment){
                allMonths.push(moment.format('YYYY-MM'));
            }, true);
            return allMonths;
        }

        /** Get object of years with values that are the number of months for that year found in range */
        function yearsWithMonthCounts(monthRange){
            return _.reduce(monthRange, function(years, month){
                var year = moment(month).format('YYYY');
                years[year] = ++years[year] || 1;
                return years;
            }, {});
        }
    }
})();

