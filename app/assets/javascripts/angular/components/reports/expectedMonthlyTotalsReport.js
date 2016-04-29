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

        vm.errorOccurred = false;

        var sum = function(numbers) {
          return _(numbers).reduce(function(total, value) { return total + value }, 0);
        }

        var activate = function() {
            var url = 'reports/expected_monthly_totals?account_list_id=' + state.current_account_list_id;
            api.call('get', url, {}, function(data) {
                vm.donations = data.donations;
                vm.total_currency = data.total_currency;
                vm.total_currency_symbol = data.total_currency_symbol;

                var donationsByType = _.groupBy(data.donations, 'type');
                vm.totalsByType = {};

                for (var type in donationsByType) {
                    var donationsForType = donationsByType[type];
                    vm.totalsByType[type] = sum(_.pluck(donationsForType,
                                                        'converted_amount'));
                }
            }, function() {
                vm.errorOccurred = true;
            });
        }

        activate();
    }
})();
