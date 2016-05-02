(function() {
    'use strict';

    angular
        .module('mpdxApp')
        .factory('monthRange', monthRangeService);

    monthRangeService.$inject = ['moment'];

    function monthRangeService(moment){
        var factory = {

            getPastMonths: getPastMonths,
            yearsWithMonthCounts: yearsWithMonthCounts,
            _getStartingMonth: getStartingMonth,
            _getThisMonth: getThisMonth,
            _generateMonthRange: generateMonthRange
        };

        activate();

        return factory;

        function activate(){

        }

        /** Get current date in format YYYY-MM-DD where DD is the last day of the month */
        function getThisMonth(){
            return moment().format('YYYY-MM') + '-' + moment().daysInMonth();
        }

        /** Get the month that is 12 months before current date in format YYYY-MM-DD where DD is the first day of the month */
        function getStartingMonth(monthsBefore){
            return moment().subtract(monthsBefore, 'months').format('YYYY-MM') + '-01';
        }

        /** Get array of months from any number of months before */
        function getPastMonths(monthsBefore){
            monthsBefore = monthsBefore || 12;
            return generateMonthRange(getStartingMonth(monthsBefore), getThisMonth())
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
