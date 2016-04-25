(function(){
    angular
        .module('mpdxApp')
        .component('donorCurrencyDonationsReport', {
            controller: donorCurrencyDonationsReportController,
            templateUrl: '/templates/reports/donorCurrencyDonations.html'
        });

    donorCurrencyDonationsReportController.$inject = ['api'];

    function donorCurrencyDonationsReportController(api) {
        var vm = this;

        vm.errorOccurred = false;

        var groupDonationsAndDonorsByCurrency = function(donations, donors) {
            vm.donorsById = _.groupBy(donors, 'id');
            var donationsByCurrency = _.groupBy(donations, 'currency');
            vm.donationsByCurrencyAndContactId = {};
            vm.currencySymbols = {};
            for (var currency in donationsByCurrency) {
                var donations = donationsByCurrency[currency];
                vm.currencySymbols[currency] = donations[0].currency_symbol;
                vm.donationsByCurrencyAndContactId[currency] =
                    _.groupBy(donations, 'contact_id');
            }

            // TODO: Fill this in with the totals by donation.converted_currency
            // for use in displaying the big bar at the top with the colors by
            // currency totals.
            vm.totalsByCurrency = {};
        };

        var activate = function() {
            api.call('get', 'reports/year_donations', {}, function(data) {
                groupDonationsAndDonorsByCurrency(
                    data.report_info.donations, data.report_info.donors
                );
            }, function() {
                vm.errorOccurred = true;
            });
        }

        activate();
    }
})();
