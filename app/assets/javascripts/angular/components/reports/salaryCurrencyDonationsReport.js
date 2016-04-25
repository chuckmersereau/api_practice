(function(){
    angular
        .module('mpdxApp')
        .component('salaryCurrencyDonationsReport', {
            controller: salaryCurrencyDonationsReportController,
            templateUrl: '/templates/reports/salaryCurrencyDonations.html'
        });

    salaryCurrencyDonationsReportController.$inject = ['api'];

    function salaryCurrencyDonationsReportController(api) {
        var vm = this;

        vm.errorOccurred = false;

        var activate = function() {
            api.call('get', 'reports/year_donations', {}, function(data) {
            }, function() {
                vm.errorOccurred = true;
            });
        }

        activate();
    }
})();
