(function(){
    angular
        .module('mpdxApp')
        .component('balancesReport', {
            controller: balancesReportController,
            templateUrl: '/templates/reports/balances.html'
        });

    balancesReportController.$inject = ['api', 'state'];

    function balancesReportController(api, state) {
        var vm = this;

        vm.errorOccurred = false;

        vm.updateTotal = updateTotal;

        activate();

        function activate() {
            var url = 'reports/balances?account_list_id=' + state.current_account_list_id;
            api.call('get', url, {}, function(data) {
                vm.designations = data.designations;
                vm.total_currency = data.total_currency;
                vm.total_currency_symbol = data.total_currency_symbol;
                includeAll(true);
            }, function() {
                vm.errorOccurred = true;
            });
        }

        function updateTotal(){
            vm.converted_total = _.reduce(vm.designations, function(sum, designation){
                return sum + (designation.balanceIncluded ? designation.converted_balance : 0);
            }, 0);
        }

        function includeAll(){
            vm.designations = _.map(vm.designations, function(designation){
                designation.balanceIncluded = true;
                return designation;
            });
            updateTotal();
        }
    }
})();
