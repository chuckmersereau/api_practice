(function(){
    angular
        .module('mpdxApp')
        .component('expectedMonthlyTotalsReport', {
            controller: expectedMonthlyTotalsReportController,
            templateUrl: '/templates/reports/expectedMonthlyTotals.html'
        });

    expectedMonthlyTotalsReportController.$inject = ['api', 'state'];

    function expectedMonthlyTotalsReportController(api, state) {
        var vm = this;

        var sumOfAllCategories = 0;

        vm.errorOccurred = false;
        vm.percentage = percentage;

        activate();

        function activate(){
            loadExpectedMonthlyTotals();
        }

        function loadExpectedMonthlyTotals() {
            var url = 'reports/expected_monthly_totals?account_list_id=' + state.current_account_list_id;
            api.call('get', url, {}, function(data) {
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
                            sum: _.sum(_.map(donationsForType, 'converted_amount'))
                        };
                    })
                    .value();
                sumOfAllCategories = _.sum(_.map(vm.donationsByType, 'sum'));
            }, function() {
                vm.errorOccurred = true;
            });
        }

        function percentage(donationType){
            if(sumOfAllCategories === 0){
                return 0;
            }
            return donationType.sum / sumOfAllCategories * 100;
        }

    }
})();
