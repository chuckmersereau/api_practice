(function() {
    'use strict';

    angular
        .module('mpdxApp')
        .factory('monthRange', monthRangeService);

    monthRangeService.$inject = ['moment'];

    function monthRangeService(moment){
        var factory = {
            allMonths: [],
            yearsWithMonthCounts: {},

            getDateFrom: getDateFrom,
            getDateTo: getDateTo,
            _generateMonthRange: generateMonthRange,
            _yearsWithMonthCounts: yearsWithMonthCounts
        };

        activate();

        return factory;

        function activate(){
            factory.allMonths = generateMonthRange(getDateFrom(), getDateTo());
            factory.yearsWithMonthCounts = yearsWithMonthCounts(factory.allMonths);
        }

        /** Get current date in format YYYY-MM-DD where DD is the last day of the month */
        function getDateTo(){
            return moment().format('YYYY-MM') + '-' + moment().daysInMonth();
        }

        /** Get the month that is 12 months before current date in format YYYY-MM-DD where DD is the first day of the month */
        function getDateFrom(){
            return moment().subtract(12, 'months').format('YYYY-MM') + '-01';
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
        function yearsWithMonthCounts(allMonths){
            return _.reduce(allMonths, function(years, month){
                var year = moment(month).format('YYYY');
                years[year] = ++years[year] || 1;
                return years;
            }, {});
        }
    }
})();
