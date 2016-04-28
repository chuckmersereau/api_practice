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
        vm.loading = true;

        vm.errorOccurred = false;
        vm.monthsBack = 12;

        vm.pastMonthDates = function() {
            var monthsBackDates = [];
            for (var i = vm.monthsBack - 1; i >= 0; i--) {
                var current = new Date();
                var date = new Date(current.setMonth(current.getMonth() - i));
                monthsBackDates.push(date);
            }
            return monthsBackDates;
        }();

        var donorTooltip = function(currency, currencySymbol, donorAndDonations) {
            var donor = donorAndDonations.donor;
            var tooltip = "";
            if (donor.pledge_amount === null || donor.pledge_amount <= 0.0) {
                if (donor.status !== null && donor.status != "") {
                    tooltip += donor.status + ". ";
                }
            } else {
                tooltip +=
                    __('Commitment ') +
                    currencySymbol + donor.pledge_amount + ' ' + currency +
                    ' ' + donor.pledge_frequency + ". ";
            }
            tooltip +=
                __('Avg.') + ' ' + currencySymbol + Math.round(donorAndDonations.average) +
                ' / ' +
                __('Min.') + ' ' + currencySymbol + Math.round(donorAndDonations.min);
            return tooltip;
        }

        vm.yearsWithMonthCounts = function() {
            var datesByYear = _.groupBy(vm.pastMonthDates, function(date) {
                return date.getFullYear();
            });
            for (var year in datesByYear) {
                datesByYear[year] = datesByYear[year].length;
            }
            return datesByYear;
        }();

        var monthIndex = function(date) {
            return date.getYear() * 12 + date.getMonth();
        }

        var currentMonthIndex = monthIndex(new Date());

        var monthsAgo = function(dateStr) {
            return currentMonthIndex - monthIndex(new Date(dateStr));
        }

        var monthlyTotals = function(donations) {
            var monthlyTotals = {};
            for (var i = 0; i < vm.monthsBack; i++) {
                monthlyTotals[i] = 0.0;
            }
            if (angular.isUndefined(donations)) {
                return monthlyTotals;
            }
            donations.forEach(function(donation) {
                var monthIndex = vm.monthsBack - monthsAgo(donation.donation_date);
                if (monthIndex < vm.monthsBack && monthIndex >= 0) {
                    monthlyTotals[monthIndex] += donation.amount;
                }
            });
            return monthlyTotals;
        }

        vm.currencyMonthlyTotals = {};
        var addToCurrencyMonthlyTotals = function(currency, monthlyTotals) {
            for (var monthIndex in monthlyTotals) {
                vm.currencyMonthlyTotals[currency][monthIndex] +=
                    monthlyTotals[monthIndex];
            }
        }

        var groupDonationsAndDonorsByCurrency = function(donations, donors) {
            vm.donorsById = _.groupBy(donors, 'id');
            var donationsByCurrency = _.groupBy(donations, 'currency');
            vm.donorsAndDonationsByCurrency = {};
            vm.currencySymbols = {};
            for (var currency in donationsByCurrency) {
                vm.currencyMonthlyTotals[currency] = {};
                for (var i = 0; i < vm.monthsBack; i++) {
                    vm.currencyMonthlyTotals[currency][i] = 0.0;
                }

                var donations = donationsByCurrency[currency];
                var currencySymbol = donations[0].currency_symbol;
                vm.currencySymbols[currency] = currencySymbol;

                var donationsByContactId = _.groupBy(donations, 'contact_id');
                var donorsAndDonations = [];
                for (var contactId in donationsByContactId) {
                    donations = donationsByContactId[contactId];
                    var amountsByMonthsAgo = monthlyTotals(donations);
                    var monthlyAmounts = [];
                    for (var monthsAgo in amountsByMonthsAgo) {
                        var amount = amountsByMonthsAgo[monthsAgo];
                        if (!isNaN(amount)) {
                            monthlyAmounts.push(amount);
                        }
                    }
                    addToCurrencyMonthlyTotals(currency, amountsByMonthsAgo);
                    var totalDonations = _.sum(monthlyAmounts);
                    var donorAndDonations = {
                        donor: vm.donorsById[contactId][0],
                        amountsByMonthsAgo: amountsByMonthsAgo,
                        total: totalDonations,
                        average: totalDonations / vm.monthsBack,
                        min: _.min(monthlyAmounts)
                    }
                    donorAndDonations.tooltip = donorTooltip(currency,
                                                             currencySymbol,
                                                             donorAndDonations);
                    donorsAndDonations.push(donorAndDonations);
                }

                vm.donorsAndDonationsByCurrency[currency] = donorsAndDonations;
            }

            // TODO: Fill this in with the totals by donation.converted_currency
            // for use in displaying the big bar at the top with the colors by
            // currency totals.
            vm.totalsByCurrency = {

            };
        };

        var activate = function() {
            api.call('get', 'reports/year_donations', {}, function(data) {
                groupDonationsAndDonorsByCurrency(
                    data.report_info.donations, data.report_info.donors
                );
                vm.loading = false;
            }, function() {
                vm.errorOccurred = true;
                vm.loading = false;
            });
        }

        activate();
    }
})();
