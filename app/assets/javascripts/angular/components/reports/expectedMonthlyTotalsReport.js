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

        var sum = function(numbers) {
          return _(numbers).reduce(function(total, value) { return total + value }, 0);
        }

        var activate = function() {
            api.call('get', '/reports/expected_monthly_totals', {}, function(data) {
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
