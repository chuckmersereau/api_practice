(function(){
    angular
        .module('mpdxApp')
        .component('balancesReport', {
            controller: balancesReportController,
            templateUrl: '/templates/reports/balances.html'
        });

    balancesReportController.$inject = ['$scope', 'api'];

    function balancesReportController($scope, api) {
        var vm = this;

        vm.errorOccurred = false;

        var sum = function(numbers) {
          return _(numbers).reduce(function(total, value) { return total + value }, 0);
        }

        var activate = function() {
            api.call('get', '/reports/balances.json', {}, function(data) {
                vm.designations = data.designations;
                vm.total_currency = data.total_currency;
                vm.total_currency_symbol = data.total_currency_symbol;
                vm.converted_total = sum(_.pluck(data.designations, 'converted_balance'));
            }, function() {
                vm.errorOccurred = true;
            });
        }

        activate();
    }
})();
