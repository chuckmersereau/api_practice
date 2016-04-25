(function(){
    angular
        .module('mpdxApp')
        .component('expectedMonthlyTotalsReport', {
            controller: expectedMonthlyTotalsReportController,
            templateUrl: '/templates/reports/expectedMonthlyTotals.html'
        });

    expectedMonthlyTotalsReportController.$inject = ['api'];

    function expectedMonthlyTotalsReportController(api) {
        var vm = this;

        vm.errorOccurred = false;

        activate();

        function activate(){
            loadExpectedMonthlyTotals();
        }

        function loadExpectedMonthlyTotals() {
            api.call('get', '/reports/expected_monthly_totals', {}, function(data) {
                vm.total_currency = data.total_currency;
                vm.total_currency_symbol = data.total_currency_symbol;

                var availableDonationTypes = ['received', 'likely', 'unlikely'];

                vm.donationsByType = _(data.donations)
                    .groupBy('type')
                    .defaults(_.zipObject(availableDonationTypes))
                    .map(function (donationsForType, type){
                        return {
                            type: type,
                            order: _.indexOf(availableDonationTypes, type),
                            donations: donationsForType,
                            sum: _.sum(_.pluck(donationsForType, 'converted_amount'))
                        };
                    })
                    .value();
            }, function() {
                vm.errorOccurred = true;
            });
        }

    }
})();
