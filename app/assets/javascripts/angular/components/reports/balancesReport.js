(function(){
    angular
        .module('mpdxApp')
        .component('balancesReport', {
            controller: balancesReportController,
            templateUrl: '/templates/reports/balances.html'
        });

    balancesReportController.$inject = ['api', 'state', '_'];

    function balancesReportController(api, state, _) {
        var vm = this;

        vm.errorOccurred = false;

        vm.updateTotal = updateTotal;

        activate();

        function activate() {
            var url = 'reports/balances?account_list_id=' + state.current_account_list_id;
            api.call('get', url, {}, function(data) {
                vm.designations = data.designations;
                vm.designations.forEach(function (d) { d.balanceIncluded = d.active; });
                vm.total_currency = data.total_currency;
                vm.total_currency_symbol = data.total_currency_symbol;
                updateTotal();
            }, function() {
                vm.errorOccurred = true;
            });
        }

        function updateTotal(){
            vm.converted_total = _.reduce(vm.designations, function(sum, designation){
                return sum + (designation.balanceIncluded ? designation.converted_balance : 0);
            }, 0);
        }
    }
})();
