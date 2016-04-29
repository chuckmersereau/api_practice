(function(){
    angular
        .module('mpdxApp')
        .component('salaryCurrencyDonationsReport', {
            controller: salaryCurrencyDonationsReportController,
            templateUrl: '/templates/reports/salaryCurrencyDonations.html'
        });

    salaryCurrencyDonationsReportController.$inject = ['api', 'state'];

    function salaryCurrencyDonationsReportController(api, state) {
        var vm = this;

        vm.errorOccurred = false;

        activate();

        function activate() {
            var url = 'reports/year_donations?account_list_id=' + state.current_account_list_id;
            api.call('get', url, {}, function(data) {
            }, function() {
                vm.errorOccurred = true;
            });
        }
    }
})();
